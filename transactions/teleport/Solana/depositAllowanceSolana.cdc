import "TeleportCustodySolana"

transaction(teleportAdmin: Address, allowedAmount: UFix64) {
  prepare(admin: auth(BorrowValue) &Account) {

    let adminRef = admin.storage.borrow<auth(TeleportCustodySolana.AdministratorEntitlement) &TeleportCustodySolana.Administrator>(from: TeleportCustodySolana.AdminStoragePath)
        ?? panic("Could not borrow a reference to the admin resource")

    let allowance <- adminRef.createAllowance(allowedAmount: allowedAmount)

    let teleportUserRef = getAccount(teleportAdmin).capabilities.borrow<&{TeleportCustodySolana.TeleportUser}>(TeleportCustodySolana.TeleportAdminTeleportUserPath)
        ?? panic("Could not borrow a reference to TeleportUser")

    teleportUserRef.depositAllowance(from: <- allowance)
  }
}