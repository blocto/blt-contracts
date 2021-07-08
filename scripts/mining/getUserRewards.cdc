import BloctoTokenMining from "../../contracts/flow/mining/BloctoTokenMining.cdc"

pub fun main(): {Address: UFix64} {
    return BloctoTokenMining.getUserRewards()
}
