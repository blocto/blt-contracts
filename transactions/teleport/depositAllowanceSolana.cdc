import TeleportCustodySolana from "../../contracts/flow/teleport/TeleportCustodySolana.cdc"

transaction(teleportAdmin: Address, allowedAmount: UFix64) {
  prepare(admin: AuthAccount) {

    let adminRef = admin.borrow<&TeleportCustodySolana.Administrator>(from: TeleportCustodySolana.AdminStoragePath)
        ?? panic("Could not borrow a reference to the admin resource")

    let allowance <- adminRef.createAllowance(allowedAmount: allowedAmount)

    let teleportUserRef = getAccount(teleportAdmin).getCapability(TeleportCustodySolana.TeleportAdminTeleportUserPath)!
        .borrow<&TeleportCustodySolana.TeleportAdmin{TeleportCustodySolana.TeleportUser}>()
        ?? panic("Could not borrow a reference to TeleportUser")

    teleportUserRef.depositAllowance(from: <- allowance)
  }
}
