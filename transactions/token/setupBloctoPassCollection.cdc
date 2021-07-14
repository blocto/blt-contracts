import NonFungibleToken from "../../contracts/flow/token/NonFungibleToken.cdc"
import BloctoPass from "../../contracts/flow/token/BloctoPass.cdc"

transaction {

    prepare(signer: AuthAccount) {
        if signer.borrow<&BloctoPass.Collection>(from: BloctoPass.CollectionStoragePath) == nil {

            let collection <- BloctoPass.createEmptyCollection() as! @BloctoPass.Collection

            signer.save(<-collection, to: BloctoPass.CollectionStoragePath)

            signer.link<&{NonFungibleToken.CollectionPublic, BloctoPass.CollectionPublic}>(
                BloctoPass.CollectionPublicPath,
                target: BloctoPass.CollectionStoragePath)
        }
    }
}
