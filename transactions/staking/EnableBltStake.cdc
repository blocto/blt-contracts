import "FungibleToken"
import "NonFungibleToken"
import "BloctoToken"
import "BloctoPass"

transaction(amount: UFix64, index: Int,  bloctoPassAddress: Address) {

    // The Vault resource that holds the tokens that are being transferred
    let vaultRef: auth(FungibleToken.Withdraw) &BloctoToken.Vault

    // The private reference to user's BloctoPass
    let bloctoPassRef: auth(BloctoPass.BloctoPassPrivateEntitlement) &BloctoPass.NFT

    prepare(signer: auth(BorrowValue, SaveValue, Capabilities) &Account) {

        // BloctoToken Vault
        if signer.storage.borrow<&BloctoToken.Vault>(from: BloctoToken.TokenStoragePath) == nil {
            // Create a new Blocto Token Vault and put it in storage
            signer.storage.save(<-BloctoToken.createEmptyVault(vaultType: Type<@BloctoToken.Vault>()), to: BloctoToken.TokenStoragePath)

            // Create a public capability to the Vault that only exposes
            // the deposit function through the Receiver interface
            let receiverCapability = signer.capabilities.storage.issue<&{FungibleToken.Receiver}>(BloctoToken.TokenStoragePath)
            signer.capabilities.publish(receiverCapability, at: BloctoToken.TokenPublicReceiverPath)

            // Create a public capability to the Vault that only exposes
            // the balance field through the Balance interface
            let balanceCapability = signer.capabilities.storage.issue<&{FungibleToken.Balance}>(BloctoToken.TokenStoragePath)
            signer.capabilities.publish(balanceCapability, at: BloctoToken.TokenPublicBalancePath)
        }

        // BloctoPass Collection
        if signer.storage.borrow<&BloctoPass.Collection>(from: BloctoPass.CollectionStoragePath) == nil {
            let collection <- BloctoPass.createEmptyCollection(nftType: Type<@BloctoPass.NFT>()) as! @BloctoPass.Collection

            signer.storage.save(<-collection, to: BloctoPass.CollectionStoragePath)

            // create a public capability for the collection
            let collectionCap = signer.capabilities.storage.issue<&BloctoPass.Collection>(BloctoPass.CollectionStoragePath)
            signer.capabilities.publish(collectionCap, at: BloctoPass.CollectionPublicPath)
        }

        let collectionRef = getAccount(signer.address).capabilities.borrow<&{NonFungibleToken.CollectionPublic, BloctoPass.CollectionPublic}>(/public/bloctoPassCollection)
        ?? panic("Could not borrow collection public reference")

        if collectionRef.getIDs().length == 0 {
            let minterRef = getAccount(bloctoPassAddress).capabilities.borrow<&{BloctoPass.MinterPublic}>(BloctoPass.MinterPublicPath)
                ?? panic("Could not borrow minter public reference")

            minterRef.mintBasicNFT(recipient: collectionRef) 
        }

        // Get a reference to the account's stored vault
        self.vaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &BloctoToken.Vault>(from: BloctoToken.TokenStoragePath)
            ?? panic("Could not borrow reference to the owner's Vault!")

        // Get a reference to the account's BloctoPass
        let bloctoPassCollectionRef = signer.storage.borrow<auth(BloctoPass.CollectionPrivateEntitlement) &BloctoPass.Collection>(from: /storage/bloctoPassCollection)
            ?? panic("Could not borrow reference to the owner's BloctoPass collection!")

        let ids: [UInt64] = bloctoPassCollectionRef.getIDs()

        // Get a reference to the BloctoPass
        self.bloctoPassRef = bloctoPassCollectionRef.borrowBloctoPassPrivate(id: ids[index])
    }

    execute {
        let lockedBalance = self.bloctoPassRef.getIdleBalance()

        if amount <= lockedBalance {
            self.bloctoPassRef.stakeNewTokens(amount: amount)
        } else if ((amount - lockedBalance) <= self.vaultRef.balance) {
            self.bloctoPassRef.deposit(from: <-self.vaultRef.withdraw(amount: amount - lockedBalance))
            self.bloctoPassRef.stakeNewTokens(amount: amount)
        } else {
            panic("Not enough tokens to stake!")
        }
    }
}