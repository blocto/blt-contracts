import TeleportCustodyBSC from "../../contracts/flow/teleport/TeleportCustodyBSC.cdc"

transaction(lockFee: UFix64, unlockFee: UFix64) {
  prepare(teleportAdmin: AuthAccount) {
    let teleportAdminRef = teleportAdmin.borrow<&TeleportCustodyBSC.TeleportAdmin>(from: TeleportCustodyBSC.TeleportAdminStoragePath)
        ?? panic("Could not borrow a reference to the teleport admin resource")
    
    teleportAdminRef.updateLockFee(fee: lockFee)
    teleportAdminRef.updateUnlockFee(fee: unlockFee)
  }
}
