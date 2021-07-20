import FungibleToken from "../../contracts/flow/token/FungibleToken.cdc"
import BloctoTokenSale from "../../contracts/flow/sale/BloctoTokenSale.cdc"

transaction(addresses: [Address]) {
    // The reference to the FLOW vault
    let vaultRef: &FungibleToken.Vault

    // The reference to the Admin Resource
    let adminRef: &BloctoTokenSale.Admin

    prepare(account: AuthAccount) {
        // Get a reference to the signer's stored vault
        self.vaultRef = account.borrow<&FungibleToken.Vault>(from: /storage/flowTokenVault)
			?? panic("Could not borrow reference to the owner's Vault!")

        // Get admin reference
        self.adminRef = account.borrow<&BloctoTokenSale.Admin>(from: BloctoTokenSale.SaleAdminStoragePath)
			?? panic("Could not borrow reference to the admin!")
    }

    execute {

        // Distribute BLT purchase to all addresses in the list
        for address in addresses {
            // Get the recipient's public account object
            let recipient = getAccount(address)

            // Get a reference to the recipient's FLOW Receiver
            let receiverRef = recipient.getCapability(/public/flowTokenReceiver)
                .borrow<&{FungibleToken.Receiver}>()
                ?? panic("Could not borrow receiver reference to the recipient's Vault")

            // Deposit the withdrawn tokens in the recipient's receiver
            receiverRef.deposit(from: <-self.vaultRef.withdraw(amount: 0.0001))

            self.adminRef.distribute(address: address)
        }
    }
}
