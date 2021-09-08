import FungibleToken from "../../contracts/flow/token/FungibleToken.cdc"
import BloctoToken from "../../contracts/flow/token/BloctoToken.cdc"

transaction {

    prepare(signer: AuthAccount) {

        let test <- signer.load<@AnyResource>(from: BloctoToken.TokenStoragePath)
        destroy test

        // If the account is already set up that's not a problem, but we don't want to replace it
        if(signer.borrow<&BloctoToken.Vault>(from: BloctoToken.TokenStoragePath) != nil) {
            return
        }
        
        // Create a new Blocto Token Vault and put it in storage
        signer.save(<-BloctoToken.createEmptyVault(), to: BloctoToken.TokenStoragePath)

        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        signer.link<&BloctoToken.Vault{FungibleToken.Receiver}>(
            BloctoToken.TokenPublicReceiverPath,
            target: BloctoToken.TokenStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the balance field through the Balance interface
        signer.link<&BloctoToken.Vault{FungibleToken.Balance}>(
            BloctoToken.TokenPublicBalancePath,
            target: BloctoToken.TokenStoragePath
        )
    }
}
