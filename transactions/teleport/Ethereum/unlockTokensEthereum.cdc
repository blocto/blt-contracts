import "FungibleToken"
import "BloctoToken"
import "TeleportCustodyEthereum"

transaction(amount: UFix64, target: Address, from: String, hash: String) {

    // The TeleportControl reference for teleport operations
    let teleportControlRef: auth(TeleportCustodyEthereum.AdminEntitlement) &{TeleportCustodyEthereum.TeleportControl}

    // The Receiver reference of the user
    let receiverRef: &{FungibleToken.Receiver}

    prepare(teleportAdmin: auth(BorrowValue) &Account) {
        self.teleportControlRef = teleportAdmin.storage.borrow<auth(TeleportCustodyEthereum.AdminEntitlement) &{TeleportCustodyEthereum.TeleportControl}>(from: TeleportCustodyEthereum.TeleportAdminStoragePath)
            ?? panic("Could not borrow a reference to TeleportControl")

        self.receiverRef = getAccount(target).capabilities.borrow<&{FungibleToken.Receiver}>(BloctoToken.TokenPublicReceiverPath)
            ?? panic("Could not borrow a reference to Receiver")
    }

    execute {
        let vault <- self.teleportControlRef.unlock(amount: amount, from: from.decodeHex(), txHash: hash)

        self.receiverRef.deposit(from: <- vault)
    }
}
