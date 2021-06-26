# Staking
### Stake BLT into BloctoPass
```
flow transactions send ./transactions/staking/stakeNewTokens.cdc \
  --network testnet \
  --arg UFix64:1000.0 \
  --signer blt-user-testnet \
  --gas-limit 1000
```

### Stake BLT that is Already in BloctoPass
```
flow transactions send ./transactions/staking/stakeNewTokensFromBloctoPass.cdc \
  --network testnet \
  --arg UFix64:1000.0 \
  --signer blt-user-testnet \
  --gas-limit 1000
```

### Switch Epoch
```
flow transactions send ./transactions/staking/switchEpoch.cdc \
  --network testnet \
  --signer blt-admin-testnet \
  --gas-limit 1000
```