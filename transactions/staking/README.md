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

### Set Epoch Token Payout
```
flow transactions send ./transactions/staking/setEpochTokenPayout.cdc \
  --network testnet \
  --arg UFix64:1000.0 \
  --signer blt-mining-testnet \
  --gas-limit 1000
```

### Switch Epoch
```
flow transactions send ./transactions/staking/switchEpoch.cdc \
  --network testnet \
  --signer blt-mining-testnet \
  --gas-limit 1000
```

### Setup Staking Admin
```
flow transactions build ./transactions/staking/setupStakingAdmin.cdc \
  --network mainnet \
  --proposer 0x0f9df91c9121c460 \
  --proposer-key-index 0 \
  --authorizer 0x0f9df91c9121c460 \
  --authorizer 0x6a5a9c49e5b2ad53 \
  --payer 0x6a5a9c49e5b2ad53 \
  --gas-limit 1000 \
  -x payload \
  --save ./build/unsigned.rlp

flow transactions sign ./build/unsigned.rlp \
  --signer blt-admin-mainnet \
  --filter payload \
  --save ./build/signed-1.rlp

flow transactions sign ./build/signed-1.rlp \
  --signer blt-staking-admin-mainnet \
  --filter payload \
  --save ./build/signed-2.rlp

flow transactions send-signed --network mainnet ./build/signed-2.rlp
```

### Setup Staking Admin
```
flow transactions build ./transactions/staking/setupStakingAdmin.cdc \
  --network testnet \
  --proposer 0x7deafdfc288e422d \
  --proposer-key-index 0 \
  --authorizer 0x7deafdfc288e422d \
  --authorizer 0x13080159c8bfe9d8 \
  --payer 0x13080159c8bfe9d8 \
  --gas-limit 1000 \
  -x payload \
  --save ./build/unsigned.rlp

flow transactions sign ./build/unsigned.rlp \
  --signer blt-staking-new-testnet \
  --filter payload \
  --save ./build/signed-1.rlp

flow transactions sign ./build/signed-1.rlp \
  --signer blt-staking-admin-testnet \
  --filter payload \
  --save ./build/signed-2.rlp

flow transactions send-signed --network testnet ./build/signed-2.rlp
```