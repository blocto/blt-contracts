import BloctoTokenStaking from "../../contracts/flow/staking/BloctoTokenStaking.cdc"

pub fun main(): UFix64 {
  return BloctoTokenStaking.getEpochTokenPayout()
}
