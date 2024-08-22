import "TeleportCustodyBSC"

transaction(lockFee: UFix64, unlockFee: UFix64) {
  prepare(teleportAdmin: auth(BorrowValue) &Account) {
    let teleportAdminRef = teleportAdmin.storage.borrow<auth(AdminEntitlement) &TeleportCustodyBSC.TeleportAdmin>(from: TeleportCustodyBSC.TeleportAdminStoragePath)
        ?? panic("Could not borrow a reference to the teleport admin resource")
    
    teleportAdminRef.updateLockFee(fee: lockFee)
    teleportAdminRef.updateUnlockFee(fee: unlockFee)
  }
}
