import FungibleToken from "../../contracts/flow/token/FungibleToken.cdc"
import TeleportedTetherToken from "../../contracts/flow/token/TeleportedTetherToken.cdc"

pub fun main(address: Address): UFix64 {
    let balanceRef = getAccount(address).getCapability(TeleportedTetherToken.TokenPublicBalancePath)
        .borrow<&{FungibleToken.Balance}>()
        ?? panic("Could not borrow balance public reference")

    return balanceRef.balance
}
