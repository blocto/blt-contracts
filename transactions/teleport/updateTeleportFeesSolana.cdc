import TeleportCustodySolana from "../../contracts/flow/teleport/TeleportCustodySolana.cdc"

transaction(lockFee: UFix64, unlockFee: UFix64) {
  prepare(teleportAdmin: AuthAccount) {
    let teleportAdminRef = teleportAdmin.borrow<&TeleportCustodySolana.TeleportAdmin>(from: TeleportCustodySolana.TeleportAdminStoragePath)
        ?? panic("Could not borrow a reference to the teleport admin resource")
    
    teleportAdminRef.updateLockFee(fee: lockFee)
    teleportAdminRef.updateUnlockFee(fee: unlockFee)
  }
}
