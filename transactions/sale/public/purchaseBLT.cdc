import NonFungibleToken from "../../../contracts/flow/token/NonFungibleToken.cdc"
import TeleportedTetherToken from "../../../contracts/flow/token/TeleportedTetherToken.cdc"
import FungibleToken from "../../../contracts/flow/token/FungibleToken.cdc"
import BloctoToken from "../../../contracts/flow/token/BloctoToken.cdc"
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

        // Create BloctoToken vault if not currently available
        if(account.borrow<&BloctoToken.Vault>(from: BloctoToken.TokenStoragePath) == nil) {
            
            // Create a new Blocto Token Vault and put it in storage
            account.save(<-BloctoToken.createEmptyVault(), to: BloctoToken.TokenStoragePath)

            // Create a public capability to the Vault that only exposes
            // the deposit function through the Receiver interface
            account.link<&BloctoToken.Vault{FungibleToken.Receiver}>(
                BloctoToken.TokenPublicReceiverPath,
                target: BloctoToken.TokenStoragePath
            )

            // Create a public capability to the Vault that only exposes
            // the balance field through the Balance interface
            account.link<&BloctoToken.Vault{FungibleToken.Balance}>(
                BloctoToken.TokenPublicBalancePath,
                target: BloctoToken.TokenStoragePath
            )
        }
    }

    execute {

        // Enroll in BLT community sale
        BloctoTokenPublicSale.purchase(from: <-self.sentVault, address: self.buyerAddress)
    }
}
