import "FungibleToken"
import "BloctoToken"
import "BloctoPass"

transaction(amount: UFix64) {

    // The Vault resource that holds the tokens that are being transferred
    let sentVault: @{FungibleToken.Vault}

    // The private reference to user's BloctoPass
    let bloctoPassRef: &BloctoPass.NFT

    prepare(signer: auth(BorrowValue) &Account) {

        // Get a reference to the signer's stored vault
        let vaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &BloctoToken.Vault>(from: BloctoToken.TokenStoragePath)
			?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the signer's stored vault
        self.sentVault <- vaultRef.withdraw(amount: amount)

        // Get a reference to the signer's BloctoPass
        let bloctoPassCollectionRef = signer.storage.borrow<auth(BloctoPass.CollectionPrivateEntitlement) &BloctoPass.Collection>(from: /storage/bloctoPassCollection)
			?? panic("Could not borrow reference to the owner's BloctoPass collection!")

        let ids = bloctoPassCollectionRef.getIDs()

        // Get a reference to the 
        self.bloctoPassRef = bloctoPassCollectionRef.borrowBloctoPassPrivate(id: ids[0])
    }

    execute {
        // Deposit BLT balance into BloctoPass first
        self.bloctoPassRef.deposit(from: <- self.sentVault)
    }
}