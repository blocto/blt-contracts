import BloctoTokenStaking from "../../contracts/flow/staking/BloctoTokenStaking.cdc"

pub fun main(): UInt64 {
    return BloctoTokenStaking.getEpoch()
}
