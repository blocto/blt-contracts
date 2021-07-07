package test

import (
	"strings"
	"testing"

	"github.com/onflow/cadence"
	emulator "github.com/onflow/flow-emulator"
	flow "github.com/onflow/flow-go-sdk"
	"github.com/onflow/flow-go-sdk/crypto"
	"github.com/onflow/flow-go-sdk/templates"
	flowgo "github.com/onflow/flow-go/model/flow"
	"github.com/stretchr/testify/assert"

	nft_contracts "github.com/onflow/flow-nft/lib/go/contracts"
)

const (
	bpGetBloctoPassVaultBalancePath = projectRootPath + "/scripts/token/getBloctoPassVaultBalance.cdc"
	bpMintBloctoPassPath            = projectRootPath + "/transactions/token/mintBloctoPass.cdc"
	bpSetupBloctoPassCollectionPath = projectRootPath + "/transactions/token/setupBloctoPassCollection.cdc"
)

type TestBloctoPassContractsInfo struct {
	FTAddr          flow.Address
	NFTAddr         flow.Address
	BTAddr          flow.Address
	BTSigner        crypto.Signer
	BTStakingAddr   flow.Address
	BTStakingSigner crypto.Signer
	BPAddr          flow.Address
	BPSigner        crypto.Signer
}

func BloctoPassDeployContract(b *emulator.Blockchain, t *testing.T) TestBloctoPassContractsInfo {
	// Should be able to deploy a contract as a new account with no keys.
	nftCode := loadNonFungibleToken()
	nftAddr, err := b.CreateAccount(
		nil,
		[]templates.Contract{
			{
				Name:   "NonFungibleToken",
				Source: string(nftCode),
			},
		})
	if !assert.NoError(t, err) {
		t.Log(err.Error())
	}
	_, err = b.CommitBlock()
	assert.NoError(t, err)

	btStakingInfo := BloctoTokenStakingDeployContract(b, t)

	bloctoPassCode := loadBloctoPass(btStakingInfo, nftAddr)

	latestBlock, err := b.GetLatestBlock()
	btStakingAccount, err := b.GetAccount(btStakingInfo.BTStakingAddr)

	tx := templates.AddAccountContract(
		btStakingInfo.BTStakingAddr,
		templates.Contract{
			Name:   "BloctoPass",
			Source: string(bloctoPassCode),
		},
	)

	tx.SetGasLimit(flowgo.DefaultMaxTransactionGasLimit).
		SetReferenceBlockID(flow.Identifier(latestBlock.ID())).
		SetProposalKey(btStakingInfo.BTStakingAddr, btStakingAccount.Keys[0].Index, btStakingAccount.Keys[0].SequenceNumber).
		SetPayer(btStakingInfo.BTStakingAddr)

	err = tx.SignEnvelope(btStakingInfo.BTStakingAddr, btStakingAccount.Keys[0].Index, btStakingInfo.BTStakingSigner)
	assert.NoError(t, err)

	err = b.AddTransaction(*tx)
	assert.NoError(t, err)

	_, err = b.CommitBlock()
	assert.NoError(t, err)

	return TestBloctoPassContractsInfo{
		FTAddr:          btStakingInfo.FTAddr,
		NFTAddr:         nftAddr,
		BTAddr:          btStakingInfo.BTAddr,
		BTSigner:        btStakingInfo.BTSigner,
		BTStakingAddr:   btStakingInfo.BTStakingAddr,
		BTStakingSigner: btStakingInfo.BTStakingSigner,
		BPAddr:          btStakingInfo.BTStakingAddr,
		BPSigner:        btStakingInfo.BTStakingSigner,
	}
}

func loadBloctoPass(btStakingInfo TestBloctoTokenStakingContractsInfo, nftAddr flow.Address) []byte {
	code := string(readFile(bloctoPassPath))

	code = strings.ReplaceAll(code, "\"./FungibleToken.cdc\"", "0x"+btStakingInfo.FTAddr.String())
	code = strings.ReplaceAll(code, "\"./NonFungibleToken.cdc\"", "0x"+nftAddr.String())
	code = strings.ReplaceAll(code, "\"./BloctoToken.cdc\"", "0x"+btStakingInfo.BTAddr.String())
	code = strings.ReplaceAll(code, "\"../staking/BloctoTokenStaking.cdc\"", "0x"+btStakingInfo.BTStakingAddr.String())

	return []byte(code)
}

func MintNewBloctoPass(
	t *testing.T, b *emulator.Blockchain, nftAddr flow.Address,
	userAddr flow.Address, userSigner crypto.Signer,
	bpAddr flow.Address, bpSigner crypto.Signer) {

	tx := flow.NewTransaction().
		SetScript(bpSetupBloctoPassCollectionTransaction(bpAddr, nftAddr)).
		SetGasLimit(100).
		SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
		SetPayer(b.ServiceKey().Address).
		AddAuthorizer(userAddr)

	signAndSubmit(
		t, b, tx,
		[]flow.Address{b.ServiceKey().Address, userAddr},
		[]crypto.Signer{b.ServiceKey().Signer(), userSigner},
		false,
	)

	tx = flow.NewTransaction().
		SetScript(bpMintBloctoPassTransaction(bpAddr, nftAddr)).
		SetGasLimit(100).
		SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
		SetPayer(b.ServiceKey().Address).
		AddAuthorizer(bpAddr)
	_ = tx.AddArgument(cadence.NewAddress(userAddr))

	signAndSubmit(
		t, b, tx,
		[]flow.Address{b.ServiceKey().Address, bpAddr},
		[]crypto.Signer{b.ServiceKey().Signer(), bpSigner},
		false,
	)
}

func loadNonFungibleToken() []byte {
	return nft_contracts.NonFungibleToken()
}

func bpMintBloctoPassTransaction(bpAddr flow.Address, nftAddr flow.Address) []byte {
	code := string(readFile(bpMintBloctoPassPath))

	code = strings.ReplaceAll(code, "\"../../contracts/flow/token/NonFungibleToken.cdc\"", "0x"+nftAddr.String())
	code = strings.ReplaceAll(code, "\"../../contracts/flow/token/BloctoPass.cdc\"", "0x"+bpAddr.String())

	return []byte(code)
}

func bpSetupBloctoPassCollectionTransaction(bpAddr flow.Address, nftAddr flow.Address) []byte {
	code := string(readFile(bpSetupBloctoPassCollectionPath))

	code = strings.ReplaceAll(code, "\"../../contracts/flow/token/NonFungibleToken.cdc\"", "0x"+nftAddr.String())
	code = strings.ReplaceAll(code, "\"../../contracts/flow/token/BloctoPass.cdc\"", "0x"+bpAddr.String())

	return []byte(code)
}

func bpGetPropertyScript(filename string, btAddr flow.Address) []byte {
	return []byte(strings.ReplaceAll(
		string(readFile(filename)),
		"\"../../contracts/flow/token/BloctoPass.cdc\"",
		"0x"+btAddr.String(),
	))
}

func bpGetBloctoPassVaultBalanceScript(bpAddr flow.Address, nftAddr flow.Address) []byte {
	code := string(readFile(bpGetBloctoPassVaultBalancePath))

	code = strings.ReplaceAll(code, "\"../../contracts/flow/token/NonFungibleToken.cdc\"", "0x"+nftAddr.String())
	code = strings.ReplaceAll(code, "\"../../contracts/flow/token/BloctoPass.cdc\"", "0x"+bpAddr.String())

	return []byte(code)
}
