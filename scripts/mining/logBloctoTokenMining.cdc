import BloctoTokenMining from "../../contracts/flow/mining/BloctoTokenMining.cdc"

pub fun main() {
    log({"miningState": BloctoTokenMining.miningState})
    log({"currentRound": BloctoTokenMining.currentRound})
    log({"currentTotalReward": BloctoTokenMining.currentTotalReward})
    log({"rewardCap": BloctoTokenMining.rewardCap})
    log({"capMultiplier": BloctoTokenMining.capMultiplier})
    log({"criterias": BloctoTokenMining.criterias})
    log({"rewardLockPeriod": BloctoTokenMining.rewardLockPeriod})
    log({"rewardLockRatio": BloctoTokenMining.rewardLockRatio})
    log({"userRewardsCollected": BloctoTokenMining.userRewardsCollected})
    log({"userRewards": BloctoTokenMining.userRewards})
    log({"rewardsDistributed": BloctoTokenMining.rewardsDistributed})
}
