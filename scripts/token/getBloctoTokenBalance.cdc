import "FungibleToken"
import "BloctoToken"

access(all)
fun main(address: Address): UFix64 {
  let vaultRef = getAccount(address).capabilities.borrow<&{FungibleToken.Vault}>(BloctoToken.TokenPublicBalancePath) 
    ?? panic("Could not borrow receiver reference to the recipient's Vault")
  return vaultRef.balance
}
