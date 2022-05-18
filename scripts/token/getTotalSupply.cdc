import BloctoToken from "../../contracts/flow/token/BloctoToken.cdc"

pub fun main(): UFix64 {
    return BloctoToken.totalSupply
}
