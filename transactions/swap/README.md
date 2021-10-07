# Swap
### Freeze Swap Pair
```
flow transactions send ./transactions/swap/freeze.cdc \
  --network testnet \
  --signer blt-swap-testnet \
  --gas-limit 1000
```

### Unfreeze Swap Pair
```
flow transactions send ./transactions/swap/unfreeze.cdc \
  --network testnet \
  --signer blt-swap-testnet \
  --gas-limit 1000
```

### Add Initial Liquidity
```
flow transactions send ./transactions/swap/addLiquidityByAdmin.cdc \
  --network testnet \
  --arg UFix64:10000.0 \
  --arg UFix64:10000.0 \
  --signer blt-swap-testnet \
  --gas-limit 1000
```

### Setup Swap Proxy
```
flow transactions build ./transactions/swap/setupSwapProxy.cdc \
  --network mainnet \
  --proposer 0xfcb06a5ae5b21a2d \
  --proposer-key-index 0 \
  --authorizer 0xfcb06a5ae5b21a2d \
  --authorizer 0x55ad22f01ef568a1 \
  --payer 0x55ad22f01ef568a1 \
  --gas-limit 1000 \
  -x payload \
  --save ./build/unsigned.rlp

flow transactions sign ./build/unsigned.rlp \
  --signer blt-swap-admin-mainnet \
  --filter payload \
  --save ./build/signed-1.rlp

flow transactions sign ./build/signed-1.rlp \
  --signer blocto-hot-wallet-mainnet \
  --filter payload \
  --save ./build/signed-2.rlp

flow transactions send-signed --network mainnet ./build/signed-2.rlp
```
