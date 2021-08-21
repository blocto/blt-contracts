import BloctoTokenMining from "../../contracts/flow/mining/BloctoTokenMining.cdc"

pub fun main(address: Address): [BloctoTokenMining.RewardLockInfo] {
    let miningRewardRef = getAccount(address).getCapability(BloctoTokenMining.MiningRewardPublicPath)
        .borrow<&{BloctoTokenMining.MiningRewardPublic}>()
        ?? panic("Could not borrow mining reward public reference")

    return miningRewardRef.getRewardsLocked()
}