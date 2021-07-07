# Token
### Setup Community Sale Lockup Schedule
```
flow transactions send ./transactions/token/admin/setupCommunitySaleSchedule.cdc \
  --network testnet \
  --signer blt-admin-testnet \
  --gas-limit 1000
```

### Mint BloctoPass NFT
```
flow transactions send ./transactions/token/admin/mintBloctoPass.cdc \
  --network testnet \
  --arg Address:0x95d4f57daf2fb5ce \
  --signer blt-admin-testnet \
  --gas-limit 1000
```

### Mint BloctoPass NFT with Custom Lockup Schedule
```
flow transactions send ./transactions/token/admin/mintBloctoPassWithCustomLockup.cdc \
  --network testnet \
  --arg Address:0x95d4f57daf2fb5ce \
  --arg UFix64:500.0 \
  --arg UFix64:1625654520.0 \
  --signer blt-admin-testnet \
  --gas-limit 1000
```

### Mint BloctoPass NFT with Predefined Lockup Schedule
```
flow transactions send ./transactions/token/admin/mintBloctoPassWithCustomLockup.cdc \
  --network testnet \
  --arg Address:0x95d4f57daf2fb5ce \
  --arg UFix64:500.0 \
  --arg Int:0 \
  --signer blt-admin-testnet \
  --gas-limit 1000
```

### Setup Blocto Token Minter
```
flow transactions send ./transactions/token/admin/setupBloctoTokenMinter.cdc \
  --network testnet \
  --arg UFix64:1000000000.0 \
  --signer blt-admin-testnet \
  --gas-limit 1000
```

### Setup BloctoToken Minter for Staking
```
flow transactions build ./transactions/token/admin/setupBloctoTokenMinterForStaking.cdc \
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

### Create Public Minter
```
flow transactions send ./transactions/token/admin/setupBloctoPassMinterPublic.cdc \
  --network testnet \
  --signer blt-admin-testnet \
  --gas-limit 1000
```
