# Teleport
### Lock BLT (Teleport to another blockchain)
```
flow transactions send ./transactions/teleport/lockTokens.cdc \
  --network testnet \
  --arg Address:0xf086a545ce3c552d \
  --arg UFix64:50.0 \
  --arg String:5251d54735bf01a20f03c44b9dd1f667373ab4da7a8c777ae2a178100e0ded80 \
  --signer blt-user-testnet \
  --gas-limit 1000
```

### Unlock BLT
```
flow transactions send ./transactions/teleport/unlockTokens.cdc \
  --network testnet \
  --arg UFix64:30.0 \
  --arg Address:0x03d1e02a48354e2b \
  --arg String:5251d54735bf01a20f03c44b9dd1f667373ab4da7a8c777ae2a178100e0ded80 \
  --arg String:7b01a77096696de1e019ea9a3c511dfbb88e4a5ec0267441c1e17477f3dfb8569b82a112b6a8a4a4f3075bee6bf1965791b3e04010c3830f3bdc4ecfdec9390e \
  --signer blt-teleport-admin-testnet \
  --gas-limit 1000
```
