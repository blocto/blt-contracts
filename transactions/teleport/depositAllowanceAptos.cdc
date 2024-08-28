import "TeleportCustodyAptos"

transaction(teleportAdmin: Address, allowedAmount: UFix64) {
  prepare(admin: AuthAccount) {

    let adminRef = admin.borrow<&TeleportCustodyAptos.Administrator>(from: TeleportCustodyAptos.AdminStoragePath)
        ?? panic("Could not borrow a reference to the admin resource")

    let allowance <- adminRef.createAllowance(allowedAmount: allowedAmount)

    let teleportUserRef = getAccount(teleportAdmin).getCapability(TeleportCustodyAptos.TeleportAdminTeleportUserPath)!
        .borrow<&TeleportCustodyAptos.TeleportAdmin{TeleportCustodyAptos.TeleportUser}>()
        ?? panic("Could not borrow a reference to TeleportUser")

    teleportUserRef.depositAllowance(from: <- allowance)
  }
}
