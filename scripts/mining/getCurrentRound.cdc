import BloctoTokenMining from "../../contracts/flow/mining/BloctoTokenMining.cdc"

pub fun main(): UInt64 {
    return BloctoTokenMining.currentRound
}
