# Blocto Token Contracts

## Setup Flow CLI
https://docs.onflow.org/flow-cli/install

## Run Scripts/Transactions - Examples
### Setup Blocto Token Vault
Build transaction
```
flow transactions build ./transactions/token/setupBloctoTokenVault.cdc \
  --network testnet \
  --proposer 0x03d1e02a48354e2b \
  --proposer-key-index 0 \
  --authorizer 0x03d1e02a48354e2b \
  --payer 0x03d1e02a48354e2b \
  --gas-limit 1000 \
  -x payload \
  --save ./build/setupBloctoTokenVault-unsigned.rlp
```

Sign transaction
```
flow transactions sign ./build/setupBloctoTokenVault-unsigned.rlp \
  --signer blt-user \
  --filter payload \
  --save ./build/setupBloctoTokenVault-signed.rlp
```

Send transaction
```
flow transactions send-signed --network testnet ./build/setupBloctoTokenVault-signed.rlp
```

### Setup Blocto Token Vault
Build Transaction
```
flow transactions build ./transactions/token/transferBloctoToken.cdc \
  --network testnet \
  --arg UFix64:100.0 \
  --arg Address:0x03d1e02a48354e2b \
  --proposer 0xccc5c610f25031c9 \
  --proposer-key-index 0 \
  --authorizer 0xccc5c610f25031c9 \
  --payer 0xccc5c610f25031c9 \
  --gas-limit 1000 \
  -x payload \
  --save ./build/transferBloctoToken-unsigned.rlp
```

Sign transaction
```
flow transactions sign ./build/transferBloctoToken-unsigned.rlp \
  --signer blt-admin \
  --filter payload \
  --save ./build/transferBloctoToken-signed.rlp
```

Send transaction
```
flow transactions send-signed --network testnet ./build/transferBloctoToken-signed.rlp
```
