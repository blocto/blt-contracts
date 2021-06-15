import NonFungibleToken from "../../contracts/flow/token/NonFungibleToken.cdc"
import BloctoPass from "../../contracts/flow/token/BloctoPass.cdc"
import BloctoTokenStaking from "../../contracts/flow/staking/BloctoTokenStaking.cdc"

pub fun main(address: Address): BloctoTokenStaking.StakerInfo {
    let collectionRef = getAccount(address).getCapability(/public/bloctoPassCollection)
        .borrow<&{NonFungibleToken.CollectionPublic, BloctoPass.CollectionPublic}>()
        ?? panic("Could not borrow collection public reference")

    let ids = collectionRef.getIDs()
    let bloctoPass = collectionRef.borrowBloctoPassPublic(id: ids[0])

    return bloctoPass.getStakingInfo()
}
