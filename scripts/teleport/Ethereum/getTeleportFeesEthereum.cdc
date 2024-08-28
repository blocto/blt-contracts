import "TeleportCustodyEthereum"

access(all)
fun main(teleportAdmin: Address): [UFix64] {
    let teleportUserRef = getAccount(teleportAdmin).capabilities.borrow<&{TeleportCustodyEthereum.TeleportUser}>(TeleportCustodyEthereum.TeleportAdminTeleportUserPath)
        ?? panic("Could not borrow a reference to TeleportUser")
    return [teleportUserRef.lockFee, teleportUserRef.unlockFee]
}