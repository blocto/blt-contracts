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

### Teleport BLT to BSC
```
flow transactions send ./transactions/teleport/lockTokensBSC.cdc \
  --network mainnet \
  --arg Address:0x55ad22f01ef568a1 \
  --arg UFix64:1.0 \
  --arg String:3f74f0af1FA2B2308dd157c7f163307e52e7fED4 \
  --signer blt-admin-mainnet \
  --gas-limit 1000
```

### Teleport BLT to Solana
```
flow transactions send ./transactions/teleport/lockTokensSolana.cdc \
  --network mainnet \
  --arg Address:0x55ad22f01ef568a1 \
  --arg UFix64:1.0 \
  --arg String:9e92afba1ffdfe595377ea62174b0a65416647bd7933f934f4e76c2ab12a3e49 \
  --arg String:SPL \
  --signer blt-admin-mainnet \
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

### Unlock BLT from BSC
```
flow transactions send ./transactions/teleport/unlockTokensBSC.cdc \
  --network mainnet \
  --arg UFix64:1.0 \
  --arg Address:0x0f9df91c9121c460 \
  --arg String:3f74f0af1FA2B2308dd157c7f163307e52e7fED4 \
  --arg String:15a6bbb03e1c1103840be66c7269769664465e805a99b99cddc9b3137100bb63 \
  --signer blocto-hot-wallet-mainnet \
  --gas-limit 1000
```

### Update BSC Teleport Fees
```
flow transactions send ./transactions/teleport/updateTeleportFeesBSC.cdc \
  --network mainnet \
  --arg UFix64:0.0 \
  --arg UFix64:0.0 \
  --signer blocto-hot-wallet-mainnet \
  --gas-limit 1000
```

### Update Solana Teleport Fees
```
flow transactions send ./transactions/teleport/updateTeleportFeesSolana.cdc \
  --network mainnet \
  --arg UFix64:0.0 \
  --arg UFix64:0.0 \
  --signer blocto-hot-wallet-mainnet \
  --gas-limit 1000
```

### Transfer BSC Teleport Fees
```
flow transactions send ./transactions/teleport/transferTeleportFeesBSC.cdc \
  --network mainnet \
  --arg Address:0x0f9df91c9121c460 \
  --signer blocto-hot-wallet-mainnet \
  --gas-limit 1000
```

### Transfer Solana Teleport Fees
```
flow transactions send ./transactions/teleport/transferTeleportFeesSolana.cdc \
  --network mainnet \
  --arg Address:0x0f9df91c9121c460 \
  --signer blocto-hot-wallet-mainnet \
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
  --authorizer 0x73d494fc6fe4b127 \
  --payer 0x73d494fc6fe4b127 \
  --gas-limit 1000 \
  -x payload \
  --save ./build/unsigned.rlp

flow transactions sign ./build/unsigned.rlp \
  --signer blt-teleport-owner-mainnet \
  --filter payload \
  --save ./build/signed-1.rlp

flow transactions sign ./build/signed-1.rlp \
  --signer blt-teleport-admin-mainnet \
  --filter payload \
  --save ./build/signed-2.rlp

flow transactions send-signed --network mainnet ./build/signed-2.rlp
```

### Deposit Allowance Ethereum
```
flow transactions send ./transactions/teleport/depositAllowanceEthereum.cdc 0x73d494fc6fe4b127 1000000.0 \
  --network mainnet \
  --signer blt-teleport-owner-mainnet \
  --gas-limit 1000
```

### Deposit Allowance Aptos
```
flow transactions send ./transactions/teleport/depositAllowanceAptos.cdc 0x73d494fc6fe4b127 1000000.0 \
  --network mainnet \
  --signer blt-teleport-owner-aptos-mainnet \
  --gas-limit 1000
```

### Deposit Allowance BSC
```
flow transactions send ./transactions/teleport/depositAllowanceBSC.cdc 0x73d494fc6fe4b127 5000000.0 \
  --network mainnet \
  --signer blt-teleport-admin-mainnet \
  --gas-limit 1000
```

### Deposit Allowance Solana
```
flow transactions send ./transactions/teleport/depositAllowanceSolana.cdc \
  --network mainnet \
  --arg Address:0x73d494fc6fe4b127 \
  --arg UFix64:5000000.0 \
  --signer blt-teleport-admin-mainnet \
  --gas-limit 1000
```
