package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/onflow/cadence"
	jsoncdc "github.com/onflow/cadence/encoding/json"
	emulator "github.com/onflow/flow-emulator"
	"github.com/onflow/flow-go-sdk"
	"github.com/onflow/flow-go-sdk/crypto"
	"github.com/onflow/flow-go-sdk/templates"
	"github.com/onflow/flow-go-sdk/test"
	"github.com/stretchr/testify/assert"
)

type TestBloctoTokenStakingContractsInfo struct {
	FTAddr          flow.Address
	BTAddr          flow.Address
	BTSigner        crypto.Signer
	BTStakingAddr   flow.Address
	BTStakingSigner crypto.Signer
}

func BloctoTokenStakingDeployContract(b *emulator.Blockchain, t *testing.T) TestBloctoTokenStakingContractsInfo {
	accountKeys := test.AccountKeyGenerator()

	fungibleAddr, bloctoTokenAddr, bloctoTokenSigner := BloctoTokenDeployContract(b, t)

	bloctoTokenStakingAccountKey, bloctoTokenStakingSigner := accountKeys.NewWithSigner()
	bloctoTokenStakingCode := loadBloctoTokenStaking(fungibleAddr, bloctoTokenAddr)

	bloctoTokenStakingAddr, err := b.CreateAccount(
		[]*flow.AccountKey{bloctoTokenStakingAccountKey},
		[]templates.Contract{{
			Name:   "BloctoTokenStaking",
			Source: string(bloctoTokenStakingCode),
		}},
	)
	assert.NoError(t, err)

	_, err = b.CommitBlock()
	assert.NoError(t, err)

	// oneUFix64, _ := cadence.NewUFix64("1.0")
	// tx, err := addAccountContractWithArgs(
	// 	bloctoTokenStakingAddr,
	// 	templates.Contract{
	// 		Name:   "BloctoTokenStaking",
	// 		Source: string(bloctoTokenStakingCode),
	// 	},
	// 	[]cadence.Value{oneUFix64},
	// )
	// assert.NoError(t, err)

	// tx = tx.
	// 	SetGasLimit(100).
	// 	SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
	// 	SetPayer(b.ServiceKey().Address)

	// signAndSubmit(
	// 	t, b, tx,
	// 	[]flow.Address{b.ServiceKey().Address, bloctoTokenStakingAddr},
	// 	[]crypto.Signer{b.ServiceKey().Signer(), bloctoTokenStakingSigner},
	// 	false,
	// )

	return TestBloctoTokenStakingContractsInfo{
		FTAddr:          fungibleAddr,
		BTAddr:          bloctoTokenAddr,
		BTSigner:        bloctoTokenSigner,
		BTStakingAddr:   bloctoTokenStakingAddr,
		BTStakingSigner: bloctoTokenStakingSigner,
	}
}

func addAccountContractWithArgs(
	signerAddr flow.Address,
	contract templates.Contract,
	args []cadence.Value,
) (*flow.Transaction, error) {
	const addAccountContractTemplate = `
	transaction(name: String, code: String %s) {
		prepare(signer: AuthAccount) {
			signer.contracts.add(name: name, code: code.decodeHex() %s)
		}
	}`

	cadenceName, _ := cadence.NewString(contract.Name)
	cadenceCode, _ := cadence.NewString(contract.SourceHex())

	tx := flow.NewTransaction().
		AddRawArgument(jsoncdc.MustEncode(cadenceName)).
		AddRawArgument(jsoncdc.MustEncode(cadenceCode)).
		AddAuthorizer(signerAddr)

	for _, arg := range args {
		arg.Type().ID()
		tx.AddRawArgument(jsoncdc.MustEncode(arg))
	}

	txArgs, addArgs := "", ""
	for i, arg := range args {
		txArgs += fmt.Sprintf(",arg%d:%s", i, arg.Type().ID())
		addArgs += fmt.Sprintf(",arg%d", i)
	}

	script := fmt.Sprintf(addAccountContractTemplate, txArgs, addArgs)
	tx.SetScript([]byte(script))

	return tx, nil
}

func loadBloctoTokenStaking(fungibleAddr flow.Address, bloctoTokenAddr flow.Address) []byte {
	code := string(readFile(bloctoTokenStakingPath))

	code = strings.ReplaceAll(code, "\"../token/FungibleToken.cdc\"", "0x"+fungibleAddr.String())
	code = strings.ReplaceAll(code, "\"../token/BloctoToken.cdc\"", "0x"+bloctoTokenAddr.String())

	return []byte(code)
}
