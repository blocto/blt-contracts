import BloctoTokenMining from "../../contracts/flow/mining/BloctoTokenMining.cdc"

pub fun main(): {String: BloctoTokenMining.Criteria} {
    return BloctoTokenMining.getCriterias()
}
