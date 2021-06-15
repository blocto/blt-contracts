import FungibleToken from "../../contracts/flow/token/FungibleToken.cdc"

pub fun main(address: Address): UFix64 {
    let balanceRef = getAccount(address).getCapability(/public/bloctoTokenBalance)
        .borrow<&{FungibleToken.Balance}>()
        ?? panic("Could not borrow balance public reference")

    return balanceRef.balance
}
