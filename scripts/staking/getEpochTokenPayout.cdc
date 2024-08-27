import "BloctoTokenStaking"

access(all)
fun main(): UFix64 {
  return BloctoTokenStaking.getEpochTokenPayout()
}
