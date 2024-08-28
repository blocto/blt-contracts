import "TeleportCustodySolana"

transaction(lockFee: UFix64, unlockFee: UFix64) {
  prepare(teleportAdmin: auth(BorrowValue) &Account) {
    let teleportAdminRef = teleportAdmin.storage.borrow<auth(TeleportCustodySolana.AdminEntitlement) &TeleportCustodySolana.TeleportAdmin>(from: TeleportCustodySolana.TeleportAdminStoragePath)
        ?? panic("Could not borrow a reference to the teleport admin resource")
    
    teleportAdminRef.updateLockFee(fee: lockFee)
    teleportAdminRef.updateUnlockFee(fee: unlockFee)
  }
}
