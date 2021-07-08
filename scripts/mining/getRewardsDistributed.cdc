import BloctoTokenMining from "../../contracts/flow/mining/BloctoTokenMining.cdc"

pub fun main(): {Address: UInt64} {
    return BloctoTokenMining.getRewardsDistributed()
}
