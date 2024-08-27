import "BloctoTokenStaking"

transaction() {
    prepare(admin: auth(BorrowValue) &Account, newAdmin: auth(Storage) &Account) {
        let adminRef =
            admin.storage.borrow<auth(BloctoTokenStaking.AdminEntitlement) &BloctoTokenStaking.Admin>
            (from: BloctoTokenStaking.StakingAdminStoragePath)
            ?? panic("Signer is not the admin")

        destroy newAdmin.storage.load<@BloctoTokenStaking.Admin>(from: BloctoTokenStaking.StakingAdminStoragePath)
        newAdmin.storage.save(<- adminRef.createNewAdmin(), to: BloctoTokenStaking.StakingAdminStoragePath)
    }
}
// following tx can be executed, but not working when newAdmin using the capability
// transaction() {
// 	prepare(admin: auth(BorrowValue, Storage, Capabilities) &Account, newAdmin: auth(BorrowValue, Storage, Capabilities) &Account) {
// 		let adminRef: &BloctoTokenStaking.Admin = admin.storage.borrow<&BloctoTokenStaking.Admin>(from: BloctoTokenStaking.StakingAdminStoragePath)
// 		?? panic("failed to borrow &BloctoTokenStaking.Admin")

// 		// admin.capabilities.unpublish(/private/bloctoTokenStakingAdmin)
// 		let adminCapability= admin.capabilities.storage.issue<&BloctoTokenStaking.Admin>(
//             	BloctoTokenStaking.StakingAdminStoragePath
//         )

// 		let oldCapability = newAdmin.storage.load<Capability>(from: BloctoTokenStaking.StakingAdminStoragePath)
// 		newAdmin.storage.save(adminCapability, to: BloctoTokenStaking.StakingAdminStoragePath)

// 	}
// }
