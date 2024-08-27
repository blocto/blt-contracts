import "FungibleToken"
import "BloctoToken"

transaction(allowedAmount: UFix64) {

    prepare(bltAdmin: auth(BorrowValue, Storage) &Account) {
        let admin = bltAdmin.storage
            .borrow<auth(BloctoToken.AdministratorEntitlement) &BloctoToken.Administrator>(from: /storage/bloctoTokenAdmin)
            ?? panic("Signer is not the admin")

        let minter <- admin.createNewMinter(allowedAmount: allowedAmount)

        destroy bltAdmin.storage.load<@BloctoToken.Minter>(from: /storage/bloctoTokenStakingMinter)
        bltAdmin.storage.save(<-minter, to: /storage/bloctoTokenStakingMinter)
    }
}
