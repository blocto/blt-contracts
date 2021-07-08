package test

import (
	"strings"
	"testing"

	"github.com/onflow/cadence"
	emulator "github.com/onflow/flow-emulator"
	"github.com/onflow/flow-go-sdk"
	"github.com/onflow/flow-go-sdk/crypto"
	"github.com/onflow/flow-go-sdk/templates"
	"github.com/onflow/flow-go-sdk/test"
	"github.com/stretchr/testify/assert"

	ft_contracts "github.com/onflow/flow-ft/lib/go/contracts"
)

const (
	btSetupBloctoTokenMinterForStakingPath = projectRootPath + "/transactions/token/admin/setupBloctoTokenMinterForStaking.cdc"
)

func BloctoTokenDeployContract(b *emulator.Blockchain, t *testing.T) (flow.Address, flow.Address, crypto.Signer) {
	accountKeys := test.AccountKeyGenerator()

	// Should be able to deploy a contract as a new account with no keys.
	fungibleTokenCode := loadFungibleToken()
	fungibleAddr, err := b.CreateAccount(
		[]*flow.AccountKey{},
		[]templates.Contract{{
			Name:   "FungibleToken",
			Source: string(fungibleTokenCode),
		}},
	)
	assert.NoError(t, err)

	_, err = b.CommitBlock()
	assert.NoError(t, err)

	bloctoTokenAccountKey, bloctoTokenSigner := accountKeys.NewWithSigner()
	bloctoTokenCode := loadBloctoToken(fungibleAddr)

	bloctoTokenAddr, err := b.CreateAccount(
		[]*flow.AccountKey{bloctoTokenAccountKey},
		[]templates.Contract{{
			Name:   "BloctoToken",
			Source: string(bloctoTokenCode),
		}},
	)
	assert.NoError(t, err)

	_, err = b.CommitBlock()
	assert.NoError(t, err)

	return fungibleAddr, bloctoTokenAddr, bloctoTokenSigner
}

func loadFungibleToken() []byte {
	return ft_contracts.FungibleToken()
}

func loadBloctoToken(fungibleAddr flow.Address) []byte {
	return []byte(strings.ReplaceAll(
		string(readFile(bloctoTokenPath)),
		"\"./FungibleToken.cdc\"",
		"0x"+fungibleAddr.String(),
	))
}

func btSetupBloctoTokenMinterForStakingTransaction(btAddr flow.Address, ftAddr flow.Address) []byte {
	code := string(readFile(btSetupBloctoTokenMinterForStakingPath))

	code = strings.ReplaceAll(code, "\"../../../contracts/flow/token/FungibleToken.cdc\"", "0x"+ftAddr.String())
	code = strings.ReplaceAll(code, "\"../../../contracts/flow/token/BloctoToken.cdc\"", "0x"+btAddr.String())

	return []byte(code)
}

func SetupBloctoTokenMinterForStaking(
	t *testing.T, b *emulator.Blockchain,
	ftAddr flow.Address, amount cadence.Value,
	btAddr flow.Address, btSigner crypto.Signer,
	minterAddr flow.Address, minterSigner crypto.Signer) {

	tx := flow.NewTransaction().
		SetScript(btSetupBloctoTokenMinterForStakingTransaction(btAddr, ftAddr)).
		SetGasLimit(100).
		SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
		SetPayer(b.ServiceKey().Address).
		AddAuthorizer(btAddr).
		AddAuthorizer(minterAddr)

	_ = tx.AddArgument(amount)

	signAndSubmit(
		t, b, tx,
		[]flow.Address{b.ServiceKey().Address, btAddr, minterAddr},
		[]crypto.Signer{b.ServiceKey().Signer(), btSigner, minterSigner},
		false,
	)
}
