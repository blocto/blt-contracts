import "FungibleToken"
import "BloctoToken"

transaction(allowedAmount: UFix64) {

    prepare(signer: auth(BorrowValue) &Account, minter: auth(Storage) &Account) {
        let admin = signer.storage
            .borrow<auth(BloctoToken.AdministratorEntitlement) &BloctoToken.Administrator>(from: /storage/bloctoTokenAdmin)
            ?? panic("Signer is not the admin")

        let minterResource <- admin.createNewMinter(allowedAmount: allowedAmount)

        minter.storage.save(<-minterResource, to: BloctoToken.TokenMinterStoragePath)
    }
}
