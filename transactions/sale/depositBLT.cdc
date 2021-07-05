import FungibleToken from "../../contracts/flow/token/FungibleToken.cdc"
import BloctoToken from "../../contracts/flow/token/BloctoToken.cdc"
import BloctoTokenSale from "../../contracts/flow/sale/BloctoTokenSale.cdc"

transaction(amount: UFix64) {

    // The reference to the Admin Resource
    let adminRef: &BloctoTokenSale.Admin

    // The tUSDT Vault resource that holds the tokens that are being transferred
    let sentVault:  @FungibleToken.Vault

    prepare(account: AuthAccount) {

        // Get admin reference
        self.adminRef = account.borrow<&BloctoTokenSale.Admin>(from: /storage/bloctoTokenSaleAdmin)
			?? panic("Could not borrow reference to the admin!")

        // Get a reference to the signer's stored vault
        let vaultRef = account.borrow<&BloctoToken.Vault>(from: BloctoToken.TokenStoragePath)
			?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the signer's stored vault
        self.sentVault <- vaultRef.withdraw(amount: amount)
    }

    execute {

        // Deposit BLT
        self.adminRef.depositBlt(from: <-self.sentVault)
    }
}
