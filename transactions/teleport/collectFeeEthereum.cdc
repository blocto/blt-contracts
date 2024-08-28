import "FungibleToken"
import "TeleportCustodyEthereum"
import "BloctoToken"

transaction(to: Address) {
  prepare(signer: AuthAccount) {
    let adminRef = signer.borrow<&TeleportCustodyEthereum.TeleportAdmin>(from: TeleportCustodyEthereum.TeleportAdminStoragePath)
        ?? panic("Could not borrow a reference to the admin resource")

    let feeAmount = adminRef.getFeeAmount();
    let vault <- adminRef.withdrawFee(amount: feeAmount);

    // Get the recipient's public account object
    let recipient = getAccount(to)

    // Get a reference to the recipient's Receiver
    let receiverRef = recipient.getCapability(BloctoToken.TokenPublicReceiverPath)
      .borrow<&{FungibleToken.Receiver}>()
      ?? panic("Could not borrow receiver reference to the recipient's Vault")

    // Deposit the withdrawn tokens in the recipient's receiver
    receiverRef.deposit(from: <-vault)
  }
}
