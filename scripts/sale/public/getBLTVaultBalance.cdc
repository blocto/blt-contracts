import BloctoTokenPublicSale from "../../../contracts/flow/sale/BloctoTokenPublicSale.cdc"

pub fun main(): UFix64 {
    return BloctoTokenPublicSale.getBltVaultBalance()
}
