# Swap
### Purchase BLT
```
flow transactions send ./transactions/sale/purchaseBLT.cdc \
  --network testnet \
  --arg UFix64:500.0 \
  --signer blt-user-testnet \
  --gas-limit 1000
```

### Deposit BLT by Admin
```
flow transactions send ./transactions/sale/depositBLT.cdc \
  --network testnet \
  --arg UFix64:50000.0 \
  --signer blt-mining-testnet \
  --gas-limit 1000
```

### Distribute BLT to Purchaser
```
flow transactions send ./transactions/sale/distribute.cdc \
  --network testnet \
  --arg Address:0x457df669b4f4d1a4 \
  --signer blt-mining-testnet \
  --gas-limit 1000
```

### Refund tUSDT to Purchaser
```
flow transactions send ./transactions/sale/refund.cdc \
  --network testnet \
  --arg Address:0x457df669b4f4d1a4 \
  --signer blt-mining-testnet \
  --gas-limit 1000
```
