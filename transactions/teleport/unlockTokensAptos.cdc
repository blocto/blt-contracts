import FungibleToken from "../../contracts/flow/token/FungibleToken.cdc"
import BloctoToken from "../../contracts/flow/token/BloctoToken.cdc"
import TeleportCustodyAptos from "../../contracts/flow/teleport/TeleportCustodyAptos.cdc"

transaction(amount: UFix64, target: Address, from: String, hash: String) {

    // The TeleportControl reference for teleport operations
    let teleportControlRef: &TeleportCustodyAptos.TeleportAdmin{TeleportCustodyAptos.TeleportControl}

    // The Receiver reference of the user
    let receiverRef: &BloctoToken.Vault{FungibleToken.Receiver}

    prepare(teleportAdmin: AuthAccount) {
        self.teleportControlRef = teleportAdmin.getCapability(TeleportCustodyAptos.TeleportAdminTeleportControlPath)
            .borrow<&TeleportCustodyAptos.TeleportAdmin{TeleportCustodyAptos.TeleportControl}>()
            ?? panic("Could not borrow a reference to TeleportControl")

        self.receiverRef = getAccount(target).getCapability(BloctoToken.TokenPublicReceiverPath)
            .borrow<&BloctoToken.Vault{FungibleToken.Receiver}>()
            ?? panic("Could not borrow a reference to Receiver")
    }

    execute {
        let vault <- self.teleportControlRef.unlock(amount: amount, from: from.decodeHex(), txHash: hash)

        self.receiverRef.deposit(from: <- vault)
    }
}
