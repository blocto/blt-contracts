import "FungibleToken"
import "BloctoToken"

transaction(allowedAmount: UFix64) {

    prepare(bltAdmin: auth(BorrowValue) &Account, stakingAdmin: auth(Storage) &Account) {
        let admin = bltAdmin.storage
            .borrow<auth(BloctoToken.AdministratorEntitlement) &BloctoToken.Administrator>(from: /storage/bloctoTokenAdmin)
            ?? panic("Signer is not the admin")

        let minter <- admin.createNewMinter(allowedAmount: allowedAmount)

        stakingAdmin.storage.save(<-minter, to: /storage/bloctoTokenStakingMinter)
    }
}
