import "BloctoTokenStaking"

access(all)
fun main(): UInt64 {
    return BloctoTokenStaking.getEpoch()
}
