import "TeleportCustodyEthereum"
import "BloctoToken"
import "FungibleToken"

access(all)
fun main(teleportAdmin: Address, user: Address): [UFix64] {
    let teleportUserRef = getAccount(teleportAdmin).capabilities.borrow<&{TeleportCustodyEthereum.TeleportUser}>(TeleportCustodyEthereum.TeleportAdminTeleportUserPath)
        ?? panic("Could not borrow a reference to TeleportUser")

    let userRef = getAccount(user).capabilities.borrow<&{FungibleToken.Balance}>(BloctoToken.TokenPublicBalancePath)
        ?? panic("Could not borrow a reference to the vault resource")

    return [teleportUserRef.allowedAmount, userRef.balance]
}