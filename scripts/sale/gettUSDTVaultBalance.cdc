import BloctoTokenSale from "../../contracts/flow/sale/BloctoTokenSale.cdc"

pub fun main(): UFix64 {
    return BloctoTokenSale.getTusdtVaultBalance()
}
