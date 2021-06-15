# Blocto Token Contracts

## Setup Flow CLI
https://docs.onflow.org/flow-cli/install

## Run Scripts/Transactions - Examples
### Setup Blocto Token Vault
```
flow transactions send ./transactions/token/setupBloctoTokenVault.cdc \
  --network testnet \
  --signer blt-user-testnet \
  --gas-limit 1000
```

### Transfer Blocto Token
```
flow transactions send ./transactions/token/transferBloctoToken.cdc \
  --network testnet \
  --arg UFix64:100.0 \
  --arg Address:0x03d1e02a48354e2b \
  --signer blt-admin-testnet \
  --gas-limit 1000
```

### Get Blocto Token Balance
```
flow scripts execute ./scripts/token/getBloctoTokenBalance.cdc \
  --network testnet \
  --arg Address:0x03d1e02a48354e2b
```
