import BloctoTokenSale from "../../../contracts/flow/sale/BloctoTokenSale.cdc"

pub fun main(): [Address] {
    return BloctoTokenSale.getPurchasers()
}
