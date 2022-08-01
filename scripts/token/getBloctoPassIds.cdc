import NonFungibleToken from "../../contracts/flow/token/NonFungibleToken.cdc"
import BloctoPass from "../../contracts/flow/token/BloctoPass.cdc"

pub fun main(address: Address): [UInt64] {
    let collectionRef = getAccount(address).getCapability(/public/bloctoPassCollection)
        .borrow<&{NonFungibleToken.CollectionPublic, BloctoPass.CollectionPublic}>()
        ?? panic("Could not borrow collection public reference")

    return collectionRef.getIDs()
}
