import BloctoTokenStaking from "../../contracts/flow/staking/BloctoTokenStaking.cdc"

transaction() {
	prepare(admin: auth(Capabilities) &Account, newAdmin: auth(BorrowValue) &Account) {
		let adminRef: &BloctoTokenStaking.Admin = admin.storage.borrow<&BloctoTokenStaking.Admin>(from: BloctoTokenStaking.StakingAdminStoragePath)
		?? panic("failed to borrow &BloctoTokenStaking.Admin")

		admin.capabilities.unpublish(/private/bloctoTokenStakingAdmin)
		let adminCapability: Capability<&BloctoTokenStaking.Admin> = admin.capabilities.storage.issue<&BloctoTokenStaking.Admin>(
            	BloctoTokenStaking.StakingAdminStoragePath
        	)

		let oldCapability = newAdmin.load<Capability>(from: BloctoTokenStaking.StakingAdminStoragePath)
		newAdmin.save<Capability<&BloctoTokenStaking.Admin>>(adminCapability, to: BloctoTokenStaking.StakingAdminStoragePath)
	}
}
