import FungibleToken from "../../contracts/flow/token/FungibleToken.cdc"
import FUSD from "../../contracts/flow/token/FUSD.cdc"

transaction(addresses: [Address], amounts: [UFix64]) {

    // The Vault resource that holds the tokens that are being transferred
    let vaultRef: &FUSD.Vault

    prepare(signer: AuthAccount) {
        assert(
            addresses.length == amounts.length,
            message: "Input length mismatch"
        )

        // Get a reference to the signer's stored vault
        self.vaultRef = signer.borrow<&FUSD.Vault>(from: /storage/fusdVault)
			?? panic("Could not borrow reference to the owner's Vault!")
    }

    execute {
        // Send FUSD to all addresses in the list
        var index = 0
        while index < addresses.length {

            if  amounts[index] > 0.0 {
            
                // Get the recipient's public account object
                let recipient = getAccount(addresses[index])

                // Get a reference to the recipient's Receiver
                let receiverRef = recipient.getCapability(/public/fusdReceiver)
                    .borrow<&{FungibleToken.Receiver}>()
                    ?? panic("Could not borrow receiver reference to the recipient's Vault: ".concat(addresses[index].toString()))

                // Deposit the withdrawn tokens in the recipient's receiver
                receiverRef.deposit(from: <-self.vaultRef.withdraw(amount: amounts[index]))

            }

            index = index + 1
        }
    }
}
