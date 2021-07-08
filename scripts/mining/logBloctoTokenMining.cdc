import BloctoTokenMining from "../../contracts/flow/mining/BloctoTokenMining.cdc"

pub fun main() {
    log({"miningState": BloctoTokenMining.getMiningState()})
    log({"currentRound": BloctoTokenMining.getCurrentRound()})
    log({"currentTotalReward": BloctoTokenMining.getCurrentTotalReward()})
    log({"rewardCap": BloctoTokenMining.getRewardCap()})
    log({"capMultiplier": BloctoTokenMining.getCapMultiplier()})
    log({"criterias": BloctoTokenMining.getCriterias()})
    log({"rewardLockPeriod": BloctoTokenMining.getRewardLockPeriod()})
    log({"rewardLockRatio": BloctoTokenMining.getRewardLockRatio()})
    log({"userRewardsCollected": BloctoTokenMining.getUserRewardsCollected()})
    log({"userRewards": BloctoTokenMining.getUserRewards()})
    log({"rewardsDistributed": BloctoTokenMining.getRewardsDistributed()})
}
