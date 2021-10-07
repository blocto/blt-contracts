import FungibleToken from "../../contracts/flow/token/FungibleToken.cdc"
import FUSD from "../../contracts/flow/token/FUSD.cdc"

transaction {

    prepare(signer: AuthAccount) {

        let VaultStoragePath = /storage/fusdVault
        let ReceiverPublicPath = /public/fusdReceiver
        let BalancePublicPath = /public/fusdBalance
        if signer.borrow<&FUSD.Vault>(from: VaultStoragePath) == nil {
            // Create a new FUSD Vault and put it in storage
            signer.save(<-FUSD.createEmptyVault(), to: VaultStoragePath)

            // Create a public capability to the Vault that only exposes
            // the deposit function through the Receiver interface
            signer.link<&FUSD.Vault{FungibleToken.Receiver}>(
                ReceiverPublicPath,
                target: VaultStoragePath
            )

            // Create a public capability to the Vault that only exposes
            // the balance field through the Balance interface
            signer.link<&FUSD.Vault{FungibleToken.Balance}>(
                BalancePublicPath,
                target: VaultStoragePath
            )
        }
    }
}
