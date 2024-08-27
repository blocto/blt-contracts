import "NonFungibleToken"
import "BloctoPass"

transaction {

    prepare(signer:  auth(BorrowValue, SaveValue, Capabilities) &Account) {
        if signer.storage.borrow<&BloctoPass.Collection>(from: BloctoPass.CollectionStoragePath) == nil {

            let collection <- BloctoPass.createEmptyCollection(nftType: Type<@BloctoPass.NFT>()) as! @BloctoPass.Collection

            signer.storage.save(<-collection, to: BloctoPass.CollectionStoragePath)

            // create a public capability for the collection
            signer.capabilities.unpublish(BloctoPass.CollectionPublicPath)
            let collectionCap = signer.capabilities.storage.issue<&BloctoPass.Collection>(BloctoPass.CollectionStoragePath)
            signer.capabilities.publish(collectionCap, at: BloctoPass.CollectionPublicPath)
        }
    }
}
