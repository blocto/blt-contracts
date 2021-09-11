# Ethereum / BSC Side of BloctoToken and TeleportCustody

## Deployed

### BSC
- BloctoToken: [0x02Bdf640fba368E7Ba5c6429cCaF251512273865](https://bscscan.com/token/0x02Bdf640fba368E7Ba5c6429cCaF251512273865)
- TeleportCustody: [0x567f7048785fcEF7944B1C980AcbB32d0CA573B7](https://bscscan.com/address/0x567f7048785fcEF7944B1C980AcbB32d0CA573B7)

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