# Swap
### Deposit BLT by Admin
```
flow transactions send ./transactions/sale/depositBLT.cdc \
  --network testnet \
  --arg UFix64:50000.0 \
  --signer blt-admin-testnet \
  --gas-limit 1000
```

### Update Lockup Schedule ID
```
flow transactions send ./transactions/sale/updateLockupScheduleId.cdc \
  --network testnet \
  --arg Int:1 \
  --signer blt-admin-testnet \
  --gas-limit 1000
```

### Purchase BLT
```
flow transactions send ./transactions/sale/purchaseBLT.cdc \
  --network testnet \
  --arg UFix64:500.0 \
  --signer blt-user-testnet \
  --gas-limit 1000
```

### Distribute BLT to Purchaser
```
flow transactions send ./transactions/sale/distribute.cdc \
  --network testnet \
  --arg Address:0x95d4f57daf2fb5ce \
  --signer blt-admin-testnet \
  --gas-limit 1000
```

### Refund tUSDT to Purchaser
```
flow transactions send ./transactions/sale/refund.cdc \
  --network testnet \
  --arg Address:0x95d4f57daf2fb5ce \
  --signer blt-admin-testnet \
  --gas-limit 1000
```
