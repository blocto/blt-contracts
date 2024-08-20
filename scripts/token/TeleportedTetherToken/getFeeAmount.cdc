import "TeleportedTetherToken"

access(all)
fun main(teleportAdmin: Address): UFix64 {
  let teleportAdminRef = getAuthAccount<auth(Storage) &Account>(teleportAdmin).storage.borrow<&TeleportedTetherToken.TeleportAdmin>(from: /storage/teleportedTetherTokenTeleportAdmin)
    ?? panic("Could not borrow a reference of TeleportAdmin")
  return teleportAdminRef.getFeeAmount()
}