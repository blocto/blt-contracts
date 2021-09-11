import TeleportCustodyEthereum from "../../contracts/flow/teleport/TeleportCustodyEthereum.cdc"

transaction(allowedAmount: UFix64) {

    prepare(admin: AuthAccount, teleportAdmin: AuthAccount) {
        let adminRef = admin.borrow<&TeleportCustodyEthereum.Administrator>(from: TeleportCustodyEthereum.AdminStoragePath)
            ?? panic("Could not borrow a reference to the admin resource")

        let teleportAdminResource <- adminRef.createNewTeleportAdmin(allowedAmount: allowedAmount)

        teleportAdmin.save(<- teleportAdminResource, to: TeleportCustodyEthereum.TeleportAdminStoragePath)

        teleportAdmin.link<&TeleportCustodyEthereum.TeleportAdmin{TeleportCustodyEthereum.TeleportUser}>(
            TeleportCustodyEthereum.TeleportAdminTeleportUserPath,
            target: TeleportCustodyEthereum.TeleportAdminStoragePath
        )

        teleportAdmin.link<&TeleportCustodyEthereum.TeleportAdmin{TeleportCustodyEthereum.TeleportControl}>(
            TeleportCustodyEthereum.TeleportAdminTeleportControlPath,
            target: TeleportCustodyEthereum.TeleportAdminStoragePath
        )
    }
}
