import "NonFungibleToken" 
import "BloctoPass"
import "BloctoTokenStaking"

access(all)
fun main(address: Address, index: Int): BloctoTokenStaking.StakerInfo {
    let collectionRef = getAccount(address).capabilities.borrow<&{NonFungibleToken.CollectionPublic, BloctoPass.CollectionPublic}>(/public/bloctoPassCollection)
        ?? panic("Could not borrow collection public reference")

    let ids = collectionRef.getIDs()
    let bloctoPass = collectionRef.borrowBloctoPassPublic(id: ids[index])

    return bloctoPass.getStakingInfo()
}
