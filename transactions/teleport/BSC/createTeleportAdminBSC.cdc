import "TeleportCustodyBSC"

transaction(allowedAmount: UFix64) {

    prepare(admin: auth(BorrowValue) &Account, teleportAdmin: auth(SaveValue, Capabilities) &Account) {
        let adminRef = admin.storage.borrow<auth(TeleportCustodyBSC.AdministratorEntitlement) &TeleportCustodyBSC.Administrator>(from: TeleportCustodyBSC.AdminStoragePath)
            ?? panic("Could not borrow a reference to the admin resource")

        let teleportAdminResource <- adminRef.createNewTeleportAdmin(allowedAmount: allowedAmount)

        teleportAdmin.storage.save(<- teleportAdminResource, to: TeleportCustodyBSC.TeleportAdminStoragePath)

        let cap = teleportAdmin.capabilities.unpublish(TeleportCustodyBSC.TeleportAdminTeleportUserPath)

        let teleportUserCap = teleportAdmin.capabilities.storage.issue<&{TeleportCustodyBSC.TeleportUser}>(TeleportCustodyBSC.TeleportAdminStoragePath)
        teleportAdmin.capabilities.publish(teleportUserCap, at: TeleportCustodyBSC.TeleportAdminTeleportUserPath)
    }
}
