# Ethereum

## Test

```sh
npm run test
```

## Deploy

### Local

```sh
npm run emulator
npm run depoly-local
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
npm run depoly-rinkeby
```