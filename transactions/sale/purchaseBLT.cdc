import FungibleToken from "../../contracts/flow/token/FungibleToken.cdc"
import TeleportedTetherToken from "../../contracts/flow/token/TeleportedTetherToken.cdc"
import BloctoTokenSale from "../../contracts/flow/sale/BloctoTokenSale.cdc"

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
    }

    execute {

        // Enroll in BLT community sale
        BloctoTokenSale.purchase(from: <-self.sentVault, address: self.buyerAddress)
    }
}
