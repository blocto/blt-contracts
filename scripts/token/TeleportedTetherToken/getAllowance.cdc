import "TeleportedTetherToken"

access(all)
fun main(teleportAdmin: Address): UFix64 {
  let teleportUserRef = getAccount(teleportAdmin).capabilities.borrow<&{TeleportedTetherToken.TeleportUser}>(/public/teleportedTetherTokenTeleportUser)
    ?? panic("Could not borrow a reference of TeleportUser")
  return teleportUserRef.allowedAmount
}
