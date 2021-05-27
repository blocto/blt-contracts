import BloctoTokenMining from "../../contracts/flow/mining/BloctoTokenMining.cdc"

pub fun main(): UFix64 {
    return BloctoTokenMining.currentTotalReward
}
