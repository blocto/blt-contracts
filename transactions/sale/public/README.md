# Swap
### Freeze Sale
```
flow transactions send ./transactions/sale/public/freeze.cdc \
  --network testnet \
  --signer blt-admin-new-testnet \
  --gas-limit 1000
```

### Unfreeze Sale
```
flow transactions send ./transactions/sale/public/unfreeze.cdc \
  --network testnet \
  --signer blt-admin-new-testnet \
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
  --network mainnet \
  --arg UFix64:600000.00000203 \
  --arg Address:0xf27a6d7cf6eee316 \
  --signer blt-sale-admin-mainnet \
  --gas-limit 1000
```

### Withdraw BLT by Admin
```
flow transactions send ./transactions/sale/public/withdrawBLT.cdc \
  --network mainnet \
  --arg UFix64:0.00000249 \
  --arg Address:0x0f9df91c9121c460 \
  --signer blt-sale-admin-mainnet \
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
  --network mainnet \
  --args-json "$(cat "./arguments/batch/distributeWithAmount.json")" \
  --signer blt-sale-admin-mainnet \
  --gas-limit 9999
```

### Refund tUSDT to Purchaser
```
flow transactions send ./transactions/sale/public/refund.cdc \
  --network testnet \
  --arg Address:0x95d4f57daf2fb5ce \
  --signer blt-admin-new-testnet \
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

### Add New Keys
```
flow transactions send ./transactions/sale/public/addPublicKey.cdc \
  --network mainnet \
  --arg String:75861f4a7b81746df8f0199d0f95d1261085b3ba3d4b1f0221fbf18284d4b759aed989a193b9e89f84932473ac5195475bd3d3081ad0180c20d5811b49e6d9c1 \
  --signer blt-sale-admin-mainnet \
  --gas-limit 9999
```
