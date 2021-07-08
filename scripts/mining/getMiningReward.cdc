import BloctoTokenMining from "../../contracts/flow/mining/BloctoTokenMining.cdc"

pub fun main(address: Address): {UInt64: UFix64} {
    let miningRewardRef = getAccount(address).getCapability(BloctoTokenMining.MiningRewardPublicPath)
        .borrow<&{BloctoTokenMining.MiningRewardPublic}>()
        ?? panic("Could not borrow mining reward public reference")

    return miningRewardRef.getRewardsLocked()
}