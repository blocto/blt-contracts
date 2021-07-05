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
  --signer blt-admin-testnet \
  --gas-limit 1000
```
