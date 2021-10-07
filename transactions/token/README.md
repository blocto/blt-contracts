# Token
### Setup BloctoToken Vault
```
flow transactions send ./transactions/token/setupBloctoTokenVault.cdc \
  --network testnet \
  --signer blt-user-testnet \
  --gas-limit 1000
```

### Transfer BloctoToken
```
flow transactions send ./transactions/token/transferBloctoToken.cdc \
  --network testnet \
  --arg UFix64:100.0 \
  --arg Address:0x03d1e02a48354e2b \
  --signer blt-admin-testnet \
  --gas-limit 1000
```

### Transfer BloctoToken in a Batch
```
flow transactions send ./transactions/token/transferBloctoTokenBatch.cdc \
  --network mainnet \
  --args-json "$(cat "./arguments/batch/transferBloctoToken.json")" \
  --signer blt-admin-mainnet \
  --gas-limit 9999
```

### Setup BloctoPass Collection
```
flow transactions send ./transactions/token/setupBloctoPassCollection.cdc \
  --network testnet \
  --signer blt-user-testnet \
  --gas-limit 1000
```

### Withdraw All Unlocked Tokens from BloctoPass
```
flow transactions send ./transactions/token/withdrawAllFromBloctoPass.cdc \
  --network testnet \
  --signer blt-user-testnet \
  --gas-limit 1000
```

### Setup tUSDT Vault
```
flow transactions send ./transactions/token/setupTeleportedTetherTokenVault.cdc \
  --network testnet \
  --signer blt-user-testnet \
  --gas-limit 1000
```
