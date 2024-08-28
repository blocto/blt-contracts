import "TeleportCustodyBSC"

access(all)
fun main(teleportAdmin: Address): UFix64 {
    let teleportUserRef = getAccount(teleportAdmin).storage.borrow<&TeleportCustodyBSC.TeleportAdmin>(TeleportCustodyBSC.TeleportAdminTeleportUserPath)
        ?? panic("Could not borrow a reference to TeleportUser")
    return teleportUserRef.feeCollector.balance
}