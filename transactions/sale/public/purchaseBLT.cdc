import NonFungibleToken from "../../../contracts/flow/token/NonFungibleToken.cdc"
import TeleportedTetherToken from "../../../contracts/flow/token/TeleportedTetherToken.cdc"
import BloctoPass from "../../../contracts/flow/token/BloctoPass.cdc"
import BloctoTokenPublicSale from "../../../contracts/flow/sale/BloctoTokenPublicSale.cdc"

transaction(amount: UFix64) {

    // The tUSDT Vault resource that holds the tokens that are being transferred
    let sentVault:  @TeleportedTetherToken.Vault

    // The address of the BLT buyer
    let buyerAddress: Address

    prepare(account: AuthAccount) {

        // Get a reference to the signer's stored vault
        let vaultRef = account.borrow<&TeleportedTetherToken.Vault>(from: TeleportedTetherToken.TokenStoragePath)
			?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the signer's stored vault
        self.sentVault <- vaultRef.withdraw(amount: amount) as! @TeleportedTetherToken.Vault

        // Record the buyer address
        self.buyerAddress = account.address

        // If user does not have BloctoPass collection yet, create one to receive
        if account.borrow<&BloctoPass.Collection>(from: BloctoPass.CollectionStoragePath) == nil {

            let collection <- BloctoPass.createEmptyCollection() as! @BloctoPass.Collection

            account.save(<-collection, to: BloctoPass.CollectionStoragePath)

            account.link<&{NonFungibleToken.CollectionPublic, BloctoPass.CollectionPublic}>(
                BloctoPass.CollectionPublicPath,
                target: BloctoPass.CollectionStoragePath)
        }
    }

    execute {

        // Enroll in BLT community sale
        BloctoTokenPublicSale.purchase(from: <-self.sentVault, address: self.buyerAddress)
    }
}
