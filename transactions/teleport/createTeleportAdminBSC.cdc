import TeleportCustodyBSC from "../../contracts/flow/teleport/TeleportCustodyBSC.cdc"

transaction(allowedAmount: UFix64) {

    prepare(admin: AuthAccount, teleportAdmin: AuthAccount) {
        let adminRef = admin.borrow<&TeleportCustodyBSC.Administrator>(from: TeleportCustodyBSC.AdminStoragePath)
            ?? panic("Could not borrow a reference to the admin resource")

        let teleportAdminResource <- adminRef.createNewTeleportAdmin(allowedAmount: allowedAmount)

        teleportAdmin.save(<- teleportAdminResource, to: TeleportCustodyBSC.TeleportAdminStoragePath)

        teleportAdmin.link<&TeleportCustodyBSC.TeleportAdmin{TeleportCustodyBSC.TeleportUser}>(
            TeleportCustodyBSC.TeleportAdminTeleportUserPath,
            target: TeleportCustodyBSC.TeleportAdminStoragePath
        )

        teleportAdmin.link<&TeleportCustodyBSC.TeleportAdmin{TeleportCustodyBSC.TeleportControl}>(
            TeleportCustodyBSC.TeleportAdminTeleportControlPath,
            target: TeleportCustodyBSC.TeleportAdminStoragePath
        )
    }
}
