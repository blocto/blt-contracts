import "FungibleToken"
import "TeleportedTetherToken"

transaction(to: Address) {

  prepare(teleportAdmin: auth(BorrowValue) &Account) {
    
    let teleportAdminRef = teleportAdmin.storage.borrow<auth(TeleportedTetherToken.TeleportControlEntitlement) &TeleportedTetherToken.TeleportAdmin>(from: /storage/teleportedTetherTokenTeleportAdmin)
      ?? panic("Could not borrow a reference of TeleportAdmin")

    let feeAmount = teleportAdminRef.getFeeAmount()
    let vault <- teleportAdminRef.withdrawFee(amount: feeAmount)

    let receiverRef = getAccount(to).capabilities.borrow<&{FungibleToken.Receiver}>(TeleportedTetherToken.TokenPublicReceiverPath)
      ?? panic("Could not borrow receiver reference to the recipient's Vault")
    receiverRef.deposit(from: <- vault)
  }
}
