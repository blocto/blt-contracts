import BloctoPass from "../../contracts/flow/token/BloctoPass.cdc"

pub fun main(address: Address): UFix64 {
    let blocoPassCollectionRef = getAccount(address).getCapability(/public/bloctoPassCollection)
        .borrow<&{BloctoPass.CollectionPublic}>()
        ?? panic("Could not borrow blocto pass collection public reference")

    let ids = blocoPassCollectionRef.getIDs()
    let bloctoPass = blocoPassCollectionRef.borrowBloctoPass(id: ids[0])

    return bloctoPass.vault.balance
}
