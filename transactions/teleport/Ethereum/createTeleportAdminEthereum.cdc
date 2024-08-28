import "TeleportCustodyEthereum"

transaction(allowedAmount: UFix64) {

    prepare(admin: auth(BorrowValue) &Account, teleportAdmin: auth(SaveValue, Capabilities) &Account) {
        let adminRef = admin.storage.borrow<auth(TeleportCustodyEthereum.AdministratorEntitlement) &TeleportCustodyEthereum.Administrator>(from: TeleportCustodyEthereum.AdminStoragePath)
            ?? panic("Could not borrow a reference to the admin resource")

        let teleportAdminResource <- adminRef.createNewTeleportAdmin(allowedAmount: allowedAmount)

        teleportAdmin.storage.save(<- teleportAdminResource, to: TeleportCustodyEthereum.TeleportAdminStoragePath)

        let cap = teleportAdmin.capabilities.unpublish(TeleportCustodyEthereum.TeleportAdminTeleportUserPath)

        let teleportUserCap = teleportAdmin.capabilities.storage.issue<&{TeleportCustodyEthereum.TeleportUser}>(TeleportCustodyEthereum.TeleportAdminStoragePath)
        teleportAdmin.capabilities.publish(teleportUserCap, at: TeleportCustodyEthereum.TeleportAdminTeleportUserPath)
    }
}
