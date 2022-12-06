import FungibleToken from "../../contracts/flow/token/FungibleToken.cdc"
import BloctoToken from "../../contracts/flow/token/BloctoToken.cdc"
import TeleportCustodyAptos from "../../contracts/flow/teleport/TeleportCustodyAptos.cdc"

transaction(admin: Address, amount: UFix64, target: String, toAddressType: String) {

    // The TeleportUser reference for teleport operations
    let teleportUserRef: &TeleportCustodyAptos.TeleportAdmin{TeleportCustodyAptos.TeleportUser}

    // The Vault resource that holds the tokens that are being transferred
    let sentVault: @FungibleToken.Vault

    prepare(signer: AuthAccount) {
        self.teleportUserRef = getAccount(admin).getCapability(TeleportCustodyAptos.TeleportAdminTeleportUserPath)
            .borrow<&TeleportCustodyAptos.TeleportAdmin{TeleportCustodyAptos.TeleportUser}>()
            ?? panic("Could not borrow a reference to TeleportOut")

        let vaultRef = signer.borrow<&BloctoToken.Vault>(from: BloctoToken.TokenStoragePath)
            ?? panic("Could not borrow a reference to the vault resource")

        self.sentVault <- vaultRef.withdraw(amount: amount)
    }

    execute {
        self.teleportUserRef.lock(from: <- self.sentVault, to: target.decodeHex(), toAddressType: toAddressType)
    }
}
