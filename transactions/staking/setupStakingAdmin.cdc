import BloctoTokenStaking from "../../contracts/flow/staking/BloctoTokenStaking.cdc"

transaction() {
	prepare(admin: AuthAccount, newAdmin: AuthAccount) {
		let adminRef = admin.borrow<&BloctoTokenStaking.Admin>(from: BloctoTokenStaking.StakingAdminStoragePath)
		?? panic("failed to borrow &BloctoTokenStaking.Admin")


		admin.unlink(/private/bloctoTokenStakingAdmin);
		let adminCapability: Capability<&BloctoTokenStaking.Admin> = admin.link<&BloctoTokenStaking.Admin>(
            	/private/bloctoTokenStakingAdmin,
            	target: BloctoTokenStaking.StakingAdminStoragePath
        	) ?? panic("failed to get capability")
		newAdmin.save<Capability<&BloctoTokenStaking.Admin>>(adminCapability, to: BloctoTokenStaking.StakingAdminStoragePath)
	}
}
