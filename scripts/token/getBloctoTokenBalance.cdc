import "FungibleToken"
import "BloctoToken"

access(all)
fun main(address: Address): UFix64 {
    let balanceRef = getAccount(address).capabilities.borrow<&{FungibleToken.Balance}>(BloctoToken.TokenPublicBalancePath) 
        ?? panic("Could not borrow balance public reference")
    return balanceRef.balance
}
