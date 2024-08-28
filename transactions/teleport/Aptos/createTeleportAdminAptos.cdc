import "TeleportCustodyAptos"

transaction(allowedAmount: UFix64) {

    prepare(admin: auth(BorrowValue) &Account, teleportAdmin: auth(SaveValue, Capabilities) &Account) {
        let adminRef = admin.storage.borrow<auth(TeleportCustodyAptos.AdministratorEntitlement) &TeleportCustodyAptos.Administrator>(from: TeleportCustodyAptos.AdminStoragePath)
            ?? panic("Could not borrow a reference to the admin resource")

        let teleportAdminResource <- adminRef.createNewTeleportAdmin(allowedAmount: allowedAmount)

        teleportAdmin.storage.save(<- teleportAdminResource, to: TeleportCustodyAptos.TeleportAdminStoragePath)

        let cap = teleportAdmin.capabilities.unpublish(TeleportCustodyAptos.TeleportAdminTeleportUserPath)

        let teleportUserCap = teleportAdmin.capabilities.storage.issue<&{TeleportCustodyAptos.TeleportUser}>(TeleportCustodyAptos.TeleportAdminStoragePath)
        teleportAdmin.capabilities.publish(teleportUserCap, at: TeleportCustodyAptos.TeleportAdminTeleportUserPath)
    }
}
