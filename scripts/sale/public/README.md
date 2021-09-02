# Sale
### Get Purchasers
```
flow scripts execute ./scripts/sale/public/getPurchasers.cdc \
  --network testnet
```

### Get Purchase Info
```
flow scripts execute ./scripts/sale/public/getPurchaseInfo.cdc \
  --network testnet \
  --arg Address:0x457df669b4f4d1a4
```

### Get BLT Vault Balance
```
flow scripts execute ./scripts/sale/public/getBLTVaultBalance.cdc \
  --network testnet
```

### Get tUSDT Vault Balance
```
flow scripts execute ./scripts/sale/public/gettUSDTVaultBalance.cdc \
  --network testnet
```
