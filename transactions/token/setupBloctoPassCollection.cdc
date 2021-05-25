import BloctoPass from "../../contracts/flow/token/BloctoPass.cdc"

transaction {

    prepare(signer: AuthAccount) {
        if signer.borrow<&BloctoPass.Collection>(from: /storage/bloctoPassCollection) == nil {

            let collection <- BloctoPass.createEmptyCollection() as! @BloctoPass.Collection

            signer.save(<-collection, to: /storage/bloctoPassCollection)

            signer.link<&{BloctoPass.CollectionPublic}>(/public/bloctoPassCollection, target: /storage/bloctoPassCollection)
        }
    }
}