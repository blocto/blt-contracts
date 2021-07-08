import FungibleToken from "../../../contracts/flow/token/FungibleToken.cdc"
import BloctoToken from "../../../contracts/flow/token/BloctoToken.cdc"

transaction(allowedAmount: UFix64) {

    prepare(signer: AuthAccount) {
        let admin = signer
            .borrow<&BloctoToken.Administrator>(from: /storage/bloctoTokenAdmin)
            ?? panic("Signer is not the admin")

        let minter <- admin.createNewMinter(allowedAmount: allowedAmount)

        signer.save(<-minter, to: BloctoToken.TokenMinterStoragePath)
    }
}
