import FungibleToken from "../../../contracts/flow/token/FungibleToken.cdc"
import TeleportedTetherToken from "../../../contracts/flow/token/TeleportedTetherToken.cdc"
import BloctoTokenPublicSale from "../../../contracts/flow/sale/BloctoTokenPublicSale.cdc"

transaction(amount: UFix64, to: Address) {

    // The reference to the Admin Resource
    let adminRef: &BloctoTokenPublicSale.Admin

    prepare(signer: AuthAccount) {

        // Get admin reference
        self.adminRef = signer.borrow<&BloctoTokenPublicSale.Admin>(from: BloctoTokenPublicSale.SaleAdminStoragePath)
			?? panic("Could not borrow reference to the admin!")
    }

    execute {

        // Withdraw tUSDT from sale contract
        let vault <- self.adminRef.withdrawTusdt(amount: amount)

        // Get the recipient's public account object
        let recipient = getAccount(to)

        // Get a reference to the recipient's Receiver
        let receiverRef = recipient.getCapability(TeleportedTetherToken.TokenPublicReceiverPath)
            .borrow<&{FungibleToken.Receiver}>()
			?? panic("Could not borrow receiver reference to the recipient's Vault")

        // Deposit the withdrawn tokens in the recipient's receiver
        receiverRef.deposit(from: <- vault)
    }
}
