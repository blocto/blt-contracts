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
  --arg Address:0x457df669b4f4d1a4 \
  --signer blt-mining-testnet \
  --gas-limit 1000
```

### Mint BloctoPass NFT with Lockup BLT
```
flow transactions send ./transactions/token/mintBloctoPassWithLockupBLT.cdc \
  --network testnet \
  --arg Address:0x457df669b4f4d1a4 \
  --arg UFix64:500.0 \
  --arg UFix64:1624699800.0 \
  --signer blt-mining-testnet \
  --gas-limit 1000
```

### Create Public Minter
```
flow transactions send ./transactions/token/setupBloctoPassMinterPublic.cdc \
  --network testnet \
  --signer blt-mining-testnet \
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

### Setup BloctoToken Minter for Staking
```
flow transactions build ./transactions/token/setupBloctoTokenMinterForStaking.cdc \
  --network testnet \
  --arg UFix64:1000000000.0 \
  --proposer 0xccc5c610f25031c9 \
  --proposer-key-index 0 \
  --authorizer 0xccc5c610f25031c9 \
  --authorizer 0x4e57c4f07871af8d \
  --payer 0x4e57c4f07871af8d \
  --gas-limit 1000 \
  -x payload \
  --save ./build/unsigned.rlp

flow transactions sign ./build/unsigned.rlp \
  --signer blt-admin-testnet \
  --filter payload \
  --save ./build/signed-1.rlp

flow transactions sign ./build/signed-1.rlp \
  --signer blt-mining-testnet \
  --filter payload \
  --save ./build/signed-2.rlp

flow transactions send-signed --network testnet ./build/signed-2.rlp
```
