import BloctoTokenPublicSale from "../../../contracts/flow/sale/BloctoTokenPublicSale.cdc"

pub fun main(): [Address] {
    return BloctoTokenPublicSale.getPurchasers()
}
