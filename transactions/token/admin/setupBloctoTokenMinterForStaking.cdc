import FungibleToken from "../../../contracts/flow/token/FungibleToken.cdc"
import BloctoToken from "../../../contracts/flow/token/BloctoToken.cdc"

transaction(allowedAmount: UFix64) {

    prepare(bltAdmin: AuthAccount, stakingAdmin: AuthAccount) {
        let admin = bltAdmin
            .borrow<&BloctoToken.Administrator>(from: /storage/bloctoTokenAdmin)
            ?? panic("Signer is not the admin")

        let minter <- admin.createNewMinter(allowedAmount: allowedAmount)

        stakingAdmin.save(<-minter, to: /storage/bloctoTokenStakingMinter)
    }
}
