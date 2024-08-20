import "FungibleToken"
import "BloctoToken"

transaction {

    prepare(signer: auth(BorrowValue, SaveValue, Capabilities) &Account) {

        // If the account is already set up that's not a problem, but we don't want to replace it
        if(signer.storage.borrow<&BloctoToken.Vault>(from: BloctoToken.TokenStoragePath) != nil) {
            return
        }
        
        // Create a new tUSDT Token Vault and put it in storage
        signer.storage.save(
            <- BloctoToken.createEmptyVault(vaultType: Type<@BloctoToken.Vault>()), 
            to: BloctoToken.TokenStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        let receiverCapability = signer.capabilities.storage.issue<&{FungibleToken.Receiver}>(BloctoToken.TokenStoragePath)
        signer.capabilities.publish(receiverCapability, at: BloctoToken.TokenPublicReceiverPath)

        // Create a public capability to the Vault that only exposes
        // the balance field through the Balance interface
        let balanceCapability = signer.capabilities.storage.issue<&{FungibleToken.Balance}>(BloctoToken.TokenStoragePath)
        signer.capabilities.publish(balanceCapability, at: BloctoToken.TokenPublicBalancePath)
    }
}