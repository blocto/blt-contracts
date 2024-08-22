import "FungibleToken"
import "BloctoToken"
import "TeleportCustodyBSC"

transaction(target: Address) {
  // The teleport admin reference
  let teleportAdminRef: auth(TeleportCustodyBSC.AdminEntitlement) &{TeleportCustodyBSC.TeleportUser}

  prepare(teleportAdmin: auth(BorrowValue) &Account) {
    self.teleportAdminRef = teleportAdmin.borrow<auth(TeleportCustodyBSC.AdminEntitlement) &{TeleportCustodyBSC.TeleportUser}>(from: TeleportCustodyBSC.TeleportAdminStoragePath)
        ?? panic("Could not borrow a reference to the teleport admin resource")
  }

  execute {
    let feeVault <- self.teleportAdminRef.withdrawFee(amount: self.teleportAdminRef.getFeeAmount())

    // Get the recipient's public account object
    let recipient = getAccount(target)

    // Get a reference to the recipient's Receiver
    let receiverRef = recipient.capabilities.borrow<&{FungibleToken.Receiver}>(BloctoToken.TokenPublicReceiverPath)
      ?? panic("Could not borrow receiver reference to the recipient's Vault")

    // Deposit the withdrawn tokens in the recipient's receiver
    receiverRef.deposit(from: <- feeVault)
  }
}
