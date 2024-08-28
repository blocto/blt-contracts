import "BloctoToken"

transaction() {

    prepare(signer: &Account) {

        let vault <- BloctoToken.createEmptyVault(vaultType: Type<@BloctoToken.Vault>())
        destroy vault
    }

    execute {
    }
}
