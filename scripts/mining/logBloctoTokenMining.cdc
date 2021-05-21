import BloctoTokenMining from "../../contracts/flow/mining/BloctoTokenMining.cdc"

pub fun main() {
    log({"miningState": BloctoTokenMining.MiningState})
    log({"currentRound": BloctoTokenMining.currentRound})
    log({"currentTotalReward": BloctoTokenMining.currentTotalReward})
    log({"rewardCap": BloctoTokenMining.rewardCap})
    log({"capMultiplier": BloctoTokenMining.capMultiplier})
    log({"criterias": BloctoTokenMining.criterias})
    log({"userRewardsCollected": BloctoTokenMining.userRewardsCollected})
    log({"userRewards": BloctoTokenMining.userRewards})
    log({"rewardsDistributed": BloctoTokenMining.rewardsDistributed})
}
