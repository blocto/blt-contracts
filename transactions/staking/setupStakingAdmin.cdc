import "BloctoTokenStaking"

transaction() {
	prepare(admin: auth(BorrowValue, Storage, Capabilities) &Account, newAdmin: auth(BorrowValue, Storage, Capabilities) &Account) {
		let adminRef: &BloctoTokenStaking.Admin = admin.storage.borrow<&BloctoTokenStaking.Admin>(from: BloctoTokenStaking.StakingAdminStoragePath)
		?? panic("failed to borrow &BloctoTokenStaking.Admin")

		// admin.capabilities.unpublish(/private/bloctoTokenStakingAdmin)
		let adminCapability: Capability<&BloctoTokenStaking.Admin> = admin.capabilities.storage.issue<&BloctoTokenStaking.Admin>(
            	BloctoTokenStaking.StakingAdminStoragePath
        )

		let oldCapability = newAdmin.storage.load<Capability>(from: BloctoTokenStaking.StakingAdminStoragePath)
		newAdmin.storage.save<Capability<&BloctoTokenStaking.Admin>>(adminCapability, to: BloctoTokenStaking.StakingAdminStoragePath)

	}
}
