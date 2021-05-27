package test

import (
	"strings"
	"testing"

	emulator "github.com/onflow/flow-emulator"
	"github.com/onflow/flow-go-sdk"
	"github.com/onflow/flow-go-sdk/crypto"
	"github.com/onflow/flow-go-sdk/templates"
	"github.com/onflow/flow-go-sdk/test"
	"github.com/stretchr/testify/assert"

	ft_contracts "github.com/onflow/flow-ft/lib/go/contracts"
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
