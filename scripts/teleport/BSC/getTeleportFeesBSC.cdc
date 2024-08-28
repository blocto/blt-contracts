import "TeleportCustodyBSC"

access(all)
fun main(teleportAdmin: Address): [UFix64] {
    let teleportUserRef = getAccount(teleportAdmin).capabilities.borrow<&{TeleportCustodyBSC.TeleportUser}>(TeleportCustodyBSC.TeleportAdminTeleportUserPath)
        ?? panic("Could not borrow a reference to TeleportUser")
    return [teleportUserRef.lockFee, teleportUserRef.unlockFee]
}