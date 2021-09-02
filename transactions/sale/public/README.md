# Swap
### Freeze Sale
```
flow transactions send ./transactions/sale/public/freeze.cdc \
  --network testnet \
  --signer blt-admin-testnet \
  --gas-limit 1000
```

### Unfreeze Sale
```
flow transactions send ./transactions/sale/public/unfreeze.cdc \
  --network testnet \
  --signer blt-admin-testnet \
  --gas-limit 1000
```

### Deposit BLT by Admin
```
flow transactions send ./transactions/sale/public/depositBLT.cdc \
  --network testnet \
  --arg UFix64:50000.0 \
  --signer blt-admin-testnet \
  --gas-limit 1000
```

### Withdraw tUSDT by Admin
```
flow transactions send ./transactions/sale/public/withdrawTusdt.cdc \
  --network testnet \
  --arg UFix64:50000.0 \
  --arg Address:0x03d1e02a48354e2b \
  --signer blt-admin-testnet \
  --gas-limit 1000
```

### Purchase BLT
```
flow transactions send ./transactions/sale/public/purchaseBLT.cdc \
  --network testnet \
  --arg UFix64:500.0 \
  --signer blt-user-testnet \
  --gas-limit 1000
```

### Distribute BLT to Purchaser
```
flow transactions send ./transactions/sale/public/distribute.cdc \
  --network testnet \
  --arg Address:0x67e7299327d1bf70 \
  --arg UFix64:500.0 \
  --signer blt-admin-testnet \
  --gas-limit 1000
```

### Distribute Locked BLT to Purchaser in a Batch
```
flow transactions send ./transactions/sale/public/distributeBatch.cdc \
  --network testnet \
  --args-json "$(cat "./arguments/distribute.json")" \
  --signer blt-admin-new-testnet \
  --gas-limit 9999
```

### Refund tUSDT to Purchaser
```
flow transactions send ./transactions/sale/public/refund.cdc \
  --network testnet \
  --arg Address:0x95d4f57daf2fb5ce \
  --signer blt-admin-testnet \
  --gas-limit 1000
```

### Refund tUSDT to Purchaser in a Batch
```
flow transactions send ./transactions/sale/public/refundBatch.cdc \
  --network testnet \
  --args-json "$(cat "./arguments/refund.json")" \
  --signer blt-admin-new-testnet \
  --gas-limit 9999
```
