import "FungibleToken"
import "TeleportCustodyBSC"
import "BloctoToken"

transaction(to: Address) {
  prepare(signer: auth(BorrowValue) &Account) {
    let adminRef = signer.storage.borrow<auth(TeleportCustodyBSC.AdminEntitlement) &TeleportCustodyBSC.TeleportAdmin>(from: TeleportCustodyBSC.TeleportAdminStoragePath)
        ?? panic("Could not borrow a reference to the admin resource")

    let feeAmount = adminRef.getFeeAmount();
    let vault <- adminRef.withdrawFee(amount: feeAmount);

    // Get the recipient's public account object
    let recipient = getAccount(to)

    // Get a reference to the recipient's Receiver
    let receiverRef = recipient.capabilities.borrow<&{FungibleToken.Receiver}>(BloctoToken.TokenPublicReceiverPath)
      ?? panic("Could not borrow receiver reference to the recipient's Vault")

    // Deposit the withdrawn tokens in the recipient's receiver
    receiverRef.deposit(from: <-vault)
  }
}
