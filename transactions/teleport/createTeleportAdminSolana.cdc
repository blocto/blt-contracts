import TeleportCustodySolana from "../../contracts/flow/teleport/TeleportCustodySolana.cdc"

transaction(allowedAmount: UFix64) {

    prepare(admin: AuthAccount, teleportAdmin: AuthAccount) {
        let adminRef = admin.borrow<&TeleportCustodySolana.Administrator>(from: TeleportCustodySolana.AdminStoragePath)
            ?? panic("Could not borrow a reference to the admin resource")

        let teleportAdminResource <- adminRef.createNewTeleportAdmin(allowedAmount: allowedAmount)

        teleportAdmin.save(<- teleportAdminResource, to: TeleportCustodySolana.TeleportAdminStoragePath)

        teleportAdmin.link<&TeleportCustodySolana.TeleportAdmin{TeleportCustodySolana.TeleportUser}>(
            TeleportCustodySolana.TeleportAdminTeleportUserPath,
            target: TeleportCustodySolana.TeleportAdminStoragePath
        )

        teleportAdmin.link<&TeleportCustodySolana.TeleportAdmin{TeleportCustodySolana.TeleportControl}>(
            TeleportCustodySolana.TeleportAdminTeleportControlPath,
            target: TeleportCustodySolana.TeleportAdminStoragePath
        )
    }
}
