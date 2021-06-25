# Mining - Examples
### Setup Mining Reward 
```
flow transactions send ./transactions/token/setupMiningReward.cdc
```

### Get Unlock Mining Reward
Return type: UFix64
```
flow scripts execute ./scripts/mining/getUnlockMiningReward.cdc \
  --arg Address:0xf8d6e0586b0a20c7
```

### Get All Mining Reward
Return type: {round: UInt64: reward: UFix64}
```
flow scripts execute ./scripts/mining/getMiningReward.cdc \
  --arg Address:0xf8d6e0586b0a20c7
```

### Withdraw Mining Reward
```
flow transactions send ./transactions/mining/withdrawReward.cdc
```