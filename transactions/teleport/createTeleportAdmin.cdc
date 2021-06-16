import TeleportCustody from "../../contracts/flow/teleport/TeleportCustody.cdc"

transaction(allowedAmount: UFix64) {

    prepare(admin: AuthAccount, teleportAdmin: AuthAccount) {
        let adminRef = admin.borrow<&TeleportCustody.Administrator>(from: /storage/teleportCustodyAdmin)
            ?? panic("Could not borrow a reference to the vault resource")

        let teleportAdminResource <- adminRef.createNewTeleportAdmin(allowedAmount: allowedAmount)

        teleportAdmin.save(<- teleportAdminResource, to: TeleportCustody.TeleportAdminStoragePath)

        teleportAdmin.link<&TeleportCustody.TeleportAdmin{TeleportCustody.TeleportUser}>(
            TeleportCustody.TeleportAdminTeleportUserPath,
            target: TeleportCustody.TeleportAdminStoragePath
        )

        teleportAdmin.link<&TeleportCustody.TeleportAdmin{TeleportCustody.TeleportControl}>(
            TeleportCustody.TeleportAdminTeleportControlPath,
            target: TeleportCustody.TeleportAdminStoragePath
        )
    }
}
