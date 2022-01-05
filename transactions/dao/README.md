# DAO - Examples
### Setup Proposer
```
flow transactions send ./transactions/dao/createProposer.cdc \
  --signer blt-dao-admin-mainnet \
  --network mainnet
```

### Propose New Topic
```
flow transactions send ./transactions/dao/proposeNewTopic.cdc \
  --signer blt-dao-admin-mainnet \
  --network mainnet
```
