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

### Setup TeleportAdminBSC
```
flow transactions build ./transactions/teleport/createTeleportAdminBSC.cdc \
  --network mainnet \
  --arg UFix64:1000000.0 \
  --proposer 0x0ac14a822e54cc4e \
  --proposer-key-index 0 \
  --authorizer 0x0ac14a822e54cc4e \
  --authorizer 0x55ad22f01ef568a1 \
  --payer 0x55ad22f01ef568a1 \
  --gas-limit 1000 \
  -x payload \
  --save ./build/unsigned.rlp

flow transactions sign ./build/unsigned.rlp \
  --signer blt-teleport-admin-mainnet \
  --filter payload \
  --save ./build/signed-1.rlp

flow transactions sign ./build/signed-1.rlp \
  --signer blocto-hot-wallet-mainnet \
  --filter payload \
  --save ./build/signed-2.rlp

flow transactions send-signed --network mainnet ./build/signed-2.rlp
```

### Setup TeleportAdminSolana
```
flow transactions build ./transactions/teleport/createTeleportAdminSolana.cdc \
  --network mainnet \
  --arg UFix64:1000000.0 \
  --proposer 0x0ac14a822e54cc4e \
  --proposer-key-index 0 \
  --authorizer 0x0ac14a822e54cc4e \
  --authorizer 0x55ad22f01ef568a1 \
  --payer 0x55ad22f01ef568a1 \
  --gas-limit 1000 \
  -x payload \
  --save ./build/unsigned.rlp

flow transactions sign ./build/unsigned.rlp \
  --signer blt-teleport-admin-mainnet \
  --filter payload \
  --save ./build/signed-1.rlp

flow transactions sign ./build/signed-1.rlp \
  --signer blocto-hot-wallet-mainnet \
  --filter payload \
  --save ./build/signed-2.rlp

flow transactions send-signed --network mainnet ./build/signed-2.rlp
```

### Setup TeleportAdminEthereum
```
flow transactions build ./transactions/teleport/createTeleportAdminEthereum.cdc \
  --network mainnet \
  --arg UFix64:1000000.0 \
  --proposer 0x0ac14a822e54cc4e \
  --proposer-key-index 0 \
  --authorizer 0x0ac14a822e54cc4e \
  --authorizer 0x55ad22f01ef568a1 \
  --payer 0x55ad22f01ef568a1 \
  --gas-limit 1000 \
  -x payload \
  --save ./build/unsigned.rlp

flow transactions sign ./build/unsigned.rlp \
  --signer blt-teleport-admin-mainnet \
  --filter payload \
  --save ./build/signed-1.rlp

flow transactions sign ./build/signed-1.rlp \
  --signer blocto-hot-wallet-mainnet \
  --filter payload \
  --save ./build/signed-2.rlp

flow transactions send-signed --network mainnet ./build/signed-2.rlp
```
