import "FungibleToken"
import "TeleportedTetherToken"

transaction(inwardFee: UFix64, outwardFee: UFix64) {

  prepare(teleportAdmin: auth(BorrowValue) &Account) {

    let teleportControlRef = teleportAdmin.storage.borrow<auth(TeleportedTetherToken.TeleportControlEntitlement) &{TeleportedTetherToken.TeleportControl}>(from: /storage/teleportedTetherTokenTeleportAdmin)
      ?? panic("Could not borrow a reference to the teleport control resource")

    teleportControlRef.updateInwardFee(fee: inwardFee)
    teleportControlRef.updateOutwardFee(fee: outwardFee)
  }
}
