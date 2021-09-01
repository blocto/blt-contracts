# Ethereum

## Test

```sh
npm run test
```

## Deploy

### Local

```sh
npm run emulator
npm run deploy-local
```

### Rinkeby

1. Set up url and deploy account in hardhat.config.ts

```js
...

networks: {
	rinkeby: {
		url: "", // rinkeby url
		accounts: [/* private key here. 0x... */],
	},
},

...
```

2. run command

```sh
npm run deploy-rinkeby
```

### BSC Testnet

1. Set up url and deploy account in hardhat.config.ts

```js
...

networks: {
	bsctestnet: {
		accounts: [/* private key here. 0x... */],
	},
},

...
```

2. run command

```sh
npm run deploy-bsc-testnet
```


## Verify

### Rinkeby

1. set up etherscan api key in `hardhat.config.ts`

```
etherscan: {
	apiKey: "", // etherscan api key here...
},
```

2. verify token

```js
npx hardhat verify --network rinkeby TOKEN_ADDRESS "BloctoToken" "BLT" 8
```

3. verify teleportCustody

```js
npx hardhat verify --network rinkeby TELEPORT_CUSTODY_ADDRESS "TOKEN_ADDRESS"
```

### BSC Testnet

1. set up bscscan api key in `hardhat.config.ts`

```
etherscan: {
	apiKey: "",
},
```

2. verify token

```js
npx hardhat verify --network bsctestnet TOKEN_ADDRESS "BloctoToken" "BLT" 8
```

3. verify teleportCustody

```js
npx hardhat verify --network bsctestnet TELEPORT_CUSTODY_ADDRESS "TOKEN_ADDRESS"
```