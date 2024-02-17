import TeleportCustodyAptos from "../../contracts/flow/teleport/TeleportCustodyAptos.cdc"

transaction(allowedAmount: UFix64) {

    prepare(admin: AuthAccount, teleportAdmin: AuthAccount) {
        let adminRef = admin.borrow<&TeleportCustodyAptos.Administrator>(from: TeleportCustodyAptos.AdminStoragePath)
            ?? panic("Could not borrow a reference to the admin resource")

        let teleportAdminResource <- adminRef.createNewTeleportAdmin(allowedAmount: allowedAmount)

        teleportAdmin.save(<- teleportAdminResource, to: TeleportCustodyAptos.TeleportAdminStoragePath)

        teleportAdmin.link<&TeleportCustodyAptos.TeleportAdmin{TeleportCustodyAptos.TeleportUser}>(
            TeleportCustodyAptos.TeleportAdminTeleportUserPath,
            target: TeleportCustodyAptos.TeleportAdminStoragePath
        )

        teleportAdmin.link<&TeleportCustodyAptos.TeleportAdmin{TeleportCustodyAptos.TeleportControl}>(
            TeleportCustodyAptos.TeleportAdminTeleportControlPath,
            target: TeleportCustodyAptos.TeleportAdminStoragePath
        )
    }
}
