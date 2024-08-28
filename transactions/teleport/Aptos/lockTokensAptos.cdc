import "FungibleToken"
import "BloctoToken"
import "TeleportCustodyAptos"

transaction(admin: Address, amount: UFix64, target: String) {

    // The TeleportUser reference for teleport operations
    let teleportUserRef: &{TeleportCustodyAptos.TeleportUser}

    // The Vault resource that holds the tokens that are being transferred
    let sentVault: @{FungibleToken.Vault}

    prepare(signer: auth(BorrowValue) &Account) {
        self.teleportUserRef = getAccount(admin).capabilities.borrow<&{TeleportCustodyAptos.TeleportUser}>(TeleportCustodyAptos.TeleportAdminTeleportUserPath)
            ?? panic("Could not borrow a reference to TeleportOut")

        let vaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &BloctoToken.Vault>(from: BloctoToken.TokenStoragePath)
            ?? panic("Could not borrow a reference to the vault resource")
        // panic(vaultRef.balance.toString().concat(" ").concat(amount.toString()))
        self.sentVault <- vaultRef.withdraw(amount: amount)
    }

    execute {
        self.teleportUserRef.lock(from: <- self.sentVault, to: target.decodeHex())
    }
}
