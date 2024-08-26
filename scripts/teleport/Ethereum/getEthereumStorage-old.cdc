import "TeleportCustodyEthereum"
import "BloctoToken"
import "FungibleToken"

pub fun main(teleportAdmin: Address, user: Address): [UFix64] {
    let teleportUserRef = getAccount(teleportAdmin).getCapability<&{TeleportCustodyEthereum.TeleportUser}>(TeleportCustodyEthereum.TeleportAdminTeleportUserPath).borrow()
        ?? panic("Could not borrow a reference to TeleportUser")

    let userRef = getAccount(user).getCapability<&{FungibleToken.Balance}>(BloctoToken.TokenPublicBalancePath).borrow()
        ?? panic("Could not borrow a reference to the vault resource")

    return [teleportUserRef.allowedAmount, userRef.balance]
}