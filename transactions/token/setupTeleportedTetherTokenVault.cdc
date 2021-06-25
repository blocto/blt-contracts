import FungibleToken from "../../contracts/flow/token/FungibleToken.cdc"
import TeleportedTetherToken from "../../contracts/flow/token/TeleportedTetherToken.cdc"

transaction {

    prepare(signer: AuthAccount) {

        // If the account is already set up that's not a problem, but we don't want to replace it
        if(signer.borrow<&TeleportedTetherToken.Vault>(from: TeleportedTetherToken.TokenStoragePath) != nil) {
            return
        }
        
        // Create a new tUSDT Token Vault and put it in storage
        signer.save(<-TeleportedTetherToken.createEmptyVault(), to: TeleportedTetherToken.TokenStoragePath)

        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        signer.link<&TeleportedTetherToken.Vault{FungibleToken.Receiver}>(
            TeleportedTetherToken.TokenPublicReceiverPath,
            target: TeleportedTetherToken.TokenStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the balance field through the Balance interface
        signer.link<&TeleportedTetherToken.Vault{FungibleToken.Balance}>(
            TeleportedTetherToken.TokenPublicBalancePath,
            target: TeleportedTetherToken.TokenStoragePath
        )
    }
}
