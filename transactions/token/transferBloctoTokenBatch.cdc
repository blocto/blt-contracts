import FungibleToken from "../../contracts/flow/token/FungibleToken.cdc"
import BloctoToken from "../../contracts/flow/token/BloctoToken.cdc"

transaction(addresses: [Address], amounts: [UFix64]) {

    // The Vault resource that holds the tokens that are being transferred
    let vaultRef: &BloctoToken.Vault

    prepare(signer: AuthAccount) {
        assert(
            addresses.length == amounts.length,
            message: "Input length mismatch"
        )

        // Get a reference to the signer's stored vault
        self.vaultRef = signer.borrow<&BloctoToken.Vault>(from: BloctoToken.TokenStoragePath)
			?? panic("Could not borrow reference to the owner's Vault!")
    }

    execute {
        // Send BLT to all addresses in the list
        var index = 0
        while index < addresses.length {
            
            // Get the recipient's public account object
            let recipient = getAccount(addresses[index])

            // Get a reference to the recipient's Receiver
            let receiverRef = recipient.getCapability(BloctoToken.TokenPublicReceiverPath)
                .borrow<&{FungibleToken.Receiver}>()
                ?? panic("Could not borrow receiver reference to the recipient's Vault: ".concat(addresses[index].toString()))

            // Deposit the withdrawn tokens in the recipient's receiver
            receiverRef.deposit(from: <-self.vaultRef.withdraw(amount: amounts[index]))

            index = index + 1
        }
    }
}
