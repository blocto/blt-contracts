import "TeleportCustodyEthereum"

transaction(teleportAdmin: Address, allowedAmount: UFix64) {
  prepare(admin: AuthAccount) {

    let adminRef = admin.borrow<&TeleportCustodyEthereum.Administrator>(from: TeleportCustodyEthereum.AdminStoragePath)
        ?? panic("Could not borrow a reference to the admin resource")

    let allowance <- adminRef.createAllowance(allowedAmount: allowedAmount)

    let teleportUserRef = getAccount(teleportAdmin).getCapability(TeleportCustodyEthereum.TeleportAdminTeleportUserPath)!
        .borrow<&TeleportCustodyEthereum.TeleportAdmin{TeleportCustodyEthereum.TeleportUser}>()
        ?? panic("Could not borrow a reference to TeleportUser")

    teleportUserRef.depositAllowance(from: <- allowance)
  }
}
