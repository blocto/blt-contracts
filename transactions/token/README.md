# Token
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

### Setup BloctoPass Collection
```
flow transactions send ./transactions/token/setupBloctoPassCollection.cdc \
  --network testnet \
  --signer blt-user-testnet \
  --gas-limit 1000
```

### Mint BloctoPass NFT
```
flow transactions send ./transactions/token/mintBloctoPass.cdc \
  --network testnet \
  --signer blt-admin-testnet \
  --gas-limit 1000
```
