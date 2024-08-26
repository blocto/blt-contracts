import "TeleportCustodyEthereum"
import "BloctoToken"
import "FungibleToken"

transaction(allowedAmount: UFix64, ethereumAddress: String, txHash: String) {

    prepare(admin: AuthAccount, teleportAdmin: AuthAccount, signer: AuthAccount) {
        pre {
            allowedAmount > 8.0: "Allowed amount must be greater than 8"
        }
        // setup blocto token vault
        // If the account is already set up that's not a problem, but we don't want to replace it
        if(signer.borrow<&BloctoToken.Vault>(from: BloctoToken.TokenStoragePath) != nil) {
            return
        }
        
        // Create a new Blocto Token Vault and put it in storage
        signer.save(
            <- BloctoToken.createEmptyVault(), 
            to: BloctoToken.TokenStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        signer.link<&{FungibleToken.Receiver}>(
            BloctoToken.TokenPublicReceiverPath,
            target: BloctoToken.TokenStoragePath)

        // Create a public capability to the Vault that only exposes
        // the balance field through the Balance interface
        signer.link<&{FungibleToken.Balance}>(
            BloctoToken.TokenPublicBalancePath,
            target: BloctoToken.TokenStoragePath)

        // mint new blocto token
        let bloctoTokenAdmin = admin.borrow<&BloctoToken.Administrator>(from: /storage/bloctoTokenAdmin)
            ?? panic("Signer is not the admin")

        let minter <- bloctoTokenAdmin.createNewMinter(allowedAmount: allowedAmount)

        let mintedAmount = allowedAmount

        let receiver = signer.borrow<&{FungibleToken.Receiver}>(from: BloctoToken.TokenStoragePath)
            ?? panic("Could not borrow a reference to the receiver")

        receiver.deposit(from: <- minter.mintTokens(amount: mintedAmount))

        destroy minter

        // setup teleport admin

        let adminRef = admin.borrow<&TeleportCustodyEthereum.Administrator>(from: TeleportCustodyEthereum.AdminStoragePath)
            ?? panic("Could not borrow a reference to the admin resource")

        let teleportAdminResource <- adminRef.createNewTeleportAdmin(allowedAmount: allowedAmount)

        teleportAdmin.save(<- teleportAdminResource, to: TeleportCustodyEthereum.TeleportAdminStoragePath)

        teleportAdmin.unlink(TeleportCustodyEthereum.TeleportAdminTeleportUserPath)

        teleportAdmin.link<&{TeleportCustodyEthereum.TeleportUser}>(
            TeleportCustodyEthereum.TeleportAdminTeleportUserPath,
            target: TeleportCustodyEthereum.TeleportAdminStoragePath)

        let teleportAdmin = teleportAdmin.borrow<&TeleportCustodyEthereum.TeleportAdmin>(from: TeleportCustodyEthereum.TeleportAdminStoragePath)
            ?? panic("Could not borrow a reference to TeleportUser")

        let allowance <- adminRef.createAllowance(allowedAmount: teleportAdmin.allowedAmount)

        teleportAdmin.depositAllowance(from: <- allowance)

        // lock tokens
        let vaultRef = signer.borrow<&BloctoToken.Vault>(from: BloctoToken.TokenStoragePath)
            ?? panic("Could not borrow a reference to the vault resource")

        let amount = vaultRef.balance / 2.0
        let sentVault <- vaultRef.withdraw(amount: amount)

        teleportAdmin.lock(from: <- sentVault, to: ethereumAddress.decodeHex())

        // unlock tokens
        let vault <- teleportAdmin.unlock(amount: amount / 2.0, from: ethereumAddress.decodeHex(), txHash: txHash)

        receiver.deposit(from: <- vault)

        // update teleport fees
        teleportAdmin.updateLockFee(fee: 0.123)
        teleportAdmin.updateUnlockFee(fee: 0.234)
    }
}
