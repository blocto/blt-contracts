import "FungibleToken"
import "TeleportedTetherToken"

transaction(isFreeze: Bool) {

  prepare(admin: auth(BorrowValue) &Account) {

    let adminRef = admin.storage.borrow<auth(TeleportedTetherToken.AdministratorEntitlement) &TeleportedTetherToken.Administrator>(from: /storage/teleportedTetherTokenAdmin)
      ?? panic("Could not borrow a reference to the admin resource")
    if (isFreeze) {
      adminRef.freeze()
    } else {
      adminRef.unfreeze()
    }
  }
}
