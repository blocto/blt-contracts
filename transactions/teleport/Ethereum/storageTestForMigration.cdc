import "TeleportCustodyEthereum"
import "BloctoToken"
import "FungibleToken"

transaction(allowedAmount: UFix64, ethereumAddress: String, txHash: String) {

    prepare(admin: auth(BorrowValue) &Account, teleportAdmin: auth(Storage, Capabilities) &Account, signer: auth(Storage, Capabilities) &Account) {

        // mint new blocto token
        let bloctoTokenAdmin = admin.storage
            .borrow<auth(BloctoToken.AdministratorEntitlement) &BloctoToken.Administrator>(from: /storage/bloctoTokenAdmin)
            ?? panic("Signer is not the admin")

        let minter <- bloctoTokenAdmin.createNewMinter(allowedAmount: allowedAmount)

        let mintedAmount = allowedAmount

        let receiver = signer.capabilities.borrow<&{FungibleToken.Receiver}>(BloctoToken.TokenPublicReceiverPath)
            ?? panic("Could not borrow a reference to the receiver")

        receiver.deposit(from: <- minter.mintTokens(amount: mintedAmount))

        destroy minter

        // setup teleport admin

        let adminRef = admin.storage.borrow<auth(TeleportCustodyEthereum.AdministratorEntitlement) &TeleportCustodyEthereum.Administrator>(from: TeleportCustodyEthereum.AdminStoragePath)
            ?? panic("Could not borrow a reference to the admin resource")

        let teleportAdmin = teleportAdmin.storage.borrow<auth(TeleportCustodyEthereum.AdminEntitlement) &TeleportCustodyEthereum.TeleportAdmin>(from: TeleportCustodyEthereum.TeleportAdminStoragePath)
            ?? panic("Could not borrow a reference to TeleportUser")

        let allowance <- adminRef.createAllowance(allowedAmount: teleportAdmin.allowedAmount)

        teleportAdmin.depositAllowance(from: <- allowance)

        // lock tokens

        let vaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &BloctoToken.Vault>(from: BloctoToken.TokenStoragePath)
            ?? panic("Could not borrow a reference to the vault resource")
        // panic(vaultRef.balance.toString().concat(" ").concat(amount.toString()))
        let amount = vaultRef.balance / 2.0
        let sentVault <- vaultRef.withdraw(amount: amount)

        teleportAdmin.lock(from: <- sentVault, to: ethereumAddress.decodeHex())

        // unlock tokens

        let vault <- teleportAdmin.unlock(amount: amount / 2.0, from: ethereumAddress.decodeHex(), txHash: txHash)

        receiver.deposit(from: <- vault)

        // update teleport fees

        teleportAdmin.updateLockFee(fee: 0.3)
        teleportAdmin.updateUnlockFee(fee: 0.11)
    }
}
