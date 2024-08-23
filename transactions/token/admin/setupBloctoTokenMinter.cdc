import "FungibleToken"
import "BloctoToken"

transaction(allowedAmount: UFix64) {

    prepare(signer: auth(Storage) &Account) {
        let admin = signer.storage
            .borrow<auth(BloctoToken.AdministratorEntitlement) &BloctoToken.Administrator>(from: /storage/bloctoTokenAdmin)
            ?? panic("Signer is not the admin")

        let minter <- admin.createNewMinter(allowedAmount: allowedAmount)

        signer.storage.save(<-minter, to: BloctoToken.TokenMinterStoragePath)
    }
}
