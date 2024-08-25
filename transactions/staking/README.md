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

## Mirgate Test Prepare

** stakingAdmin **
Private Key 3846de1ad81d03171dcf0cda76abdd862410fa82a16bcbdcafd480ce596fa12d
address: 0x01cf0e2f2f715450

```
 flow accounts create --key  a234ec4e3e892352a870a1c936eb72ab106b212dda69953a2b080d977b88380a8a78a23f7a56432c3db2d757be94e34cf9274a3850ceab608d749b83ad37e631 --signer emulator-account
```

** staker **

address: 0x179b6b1cb6755e31
Private Key cfbfbd83d41255d524d47847c76c331bdbea8147fee772a9946b70f0b435798d

```
 flow accounts create --key  3a06740567ed4512bc87a371156073eb45a4e8ad4508b9eefba3c1849d5bb9728814207d1698662c06f19e38eec95b6bc9b1349cb46f75ff80905a7b56f1845b --signer emulator-account
```

## Migrate Test

### Deploy Contract

Old Emulator

```
flow accounts add-contract contracts/flow/token/BloctoToken.cdc --signer emulator-account
```

```
flow accounts add-contract contracts/flow/staking/BloctoTokenStaking.cdc --signer emulator-account
```

```
flow accounts add-contract contracts/flow/token/BloctoPassStamp.cdc --signer emulator-account
```

```
flow accounts add-contract contracts/flow/token/BloctoPass.cdc --signer emulator-account
```

### Add Data

admin

```
flow transactions send ./transactions/token/admin/setupBloctoPassMinterPublic.cdc \
    --signer emulator-account
```

staker1 setup Blocto

```
flow transactions send ./transactions/token/setupBloctoTokenVault.cdc \
  --signer staker
```

send 10000 to staker

```
flow transactions send ./transactions/token/transferBloctoToken.cdc 10000.0 0x179b6b1cb6755e31 \
  --signer emulator-account
```

balance check

```
flow scripts execute ./scripts/token/getBloctoTokenBalance.cdc 0x179b6b1cb6755e31
```

send 10000 to staker

```
flow transactions send ./transactions/staking-app/EnableBltStake.cdc 8000.0 0 \
    --signer staker
```

staker stake 8000

```
flow transactions send ./transactions/staking/app/EnableBltStake.cdc 8000.0 0 \
    --signer staker
```

get stakingInfo

```
flow scripts execute ./scripts/staking/getStakingInfo.cdc 0x179b6b1cb6755e31 0
```

### migrate

1. copy flowdb folder from old repo
2. NOTE: flow.json may not use source in contracts, like following

```
"BloctoPass": "./contracts/flow/token/BloctoPass.cdc",
```

3. following cmd

```
flow-c1 migrate state --db-path=./flowdb/emulator.sqlite --save-report=./reports  --contracts "BloctoToken" --contracts "BloctoTokenStaking" --contracts "BloctoPassStamp" --contracts "BloctoPass" > flowdb/result.log  2>&1
```

new flow-c1 test

```
flow-c1 transactions send ./transactions/staking/app/EnableBltStake.cdc 1000.0 0 0xf8d6e0586b0a20c7 \
    --signer staker
```

```
flow-c1 scripts execute ./scripts/staking/getStakingInfo.cdc 0x179b6b1cb6755e31 0
```
