import "TeleportCustodySolana"

transaction(allowedAmount: UFix64) {

    prepare(admin: auth(BorrowValue) &Account, teleportAdmin: auth(SaveValue, Capabilities) &Account) {
        let adminRef = admin.storage.borrow<auth(TeleportCustodySolana.AdministratorEntitlement) &TeleportCustodySolana.Administrator>(from: TeleportCustodySolana.AdminStoragePath)
            ?? panic("Could not borrow a reference to the admin resource")

        let teleportAdminResource <- adminRef.createNewTeleportAdmin(allowedAmount: allowedAmount)

        teleportAdmin.storage.save(<- teleportAdminResource, to: TeleportCustodySolana.TeleportAdminStoragePath)

        let cap = teleportAdmin.capabilities.unpublish(TeleportCustodySolana.TeleportAdminTeleportUserPath)

        let teleportUserCap = teleportAdmin.capabilities.storage.issue<&{TeleportCustodySolana.TeleportUser}>(TeleportCustodySolana.TeleportAdminStoragePath)
        teleportAdmin.capabilities.publish(teleportUserCap, at: TeleportCustodySolana.TeleportAdminTeleportUserPath)
    }
}
