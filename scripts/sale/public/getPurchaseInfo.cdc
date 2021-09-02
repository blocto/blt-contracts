import BloctoTokenPublicSale from "../../../contracts/flow/sale/BloctoTokenPublicSale.cdc"

pub fun main(address: Address): BloctoTokenPublicSale.PurchaseInfo? {
    return BloctoTokenPublicSale.getPurchase(address: address)
}
