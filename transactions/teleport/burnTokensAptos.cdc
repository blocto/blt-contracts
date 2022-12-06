import FungibleToken from "../../contracts/flow/token/FungibleToken.cdc"
import BloctoToken from "../../contracts/flow/token/BloctoToken.cdc"
import TeleportCustodyAptos from "../../contracts/flow/teleport/TeleportCustodyAptos.cdc"

transaction(amount: UFix64, from: String, hash: String) {

    // The TeleportControl reference for teleport operations
    let teleportControlRef: &TeleportCustodyAptos.TeleportAdmin{TeleportCustodyAptos.TeleportControl}

    prepare(teleportAdmin: AuthAccount) {
        self.teleportControlRef = teleportAdmin.getCapability(TeleportCustodyAptos.TeleportAdminTeleportControlPath)
            .borrow<&TeleportCustodyAptos.TeleportAdmin{TeleportCustodyAptos.TeleportControl}>()
            ?? panic("Could not borrow a reference to TeleportControl")
    }

    execute {
        self.teleportControlRef.updateUnlockFee(fee: 0.0)
        let vault <- self.teleportControlRef.unlock(amount: amount, from: from.decodeHex(), txHash: hash)
        self.teleportControlRef.updateUnlockFee(fee: 0.1)

        destroy vault
    }
}
