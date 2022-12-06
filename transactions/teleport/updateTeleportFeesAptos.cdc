import TeleportCustodyAptos from "../../contracts/flow/teleport/TeleportCustodyAptos.cdc"

transaction(lockFee: UFix64, unlockFee: UFix64) {
  prepare(teleportAdmin: AuthAccount) {
    let teleportAdminRef = teleportAdmin.borrow<&TeleportCustodyAptos.TeleportAdmin>(from: TeleportCustodyAptos.TeleportAdminStoragePath)
        ?? panic("Could not borrow a reference to the teleport admin resource")
    
    teleportAdminRef.updateLockFee(fee: lockFee)
    teleportAdminRef.updateUnlockFee(fee: unlockFee)
  }
}
