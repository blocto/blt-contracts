import BloctoTokenStaking from "../../contracts/flow/staking/BloctoTokenStaking.cdc"

transaction(amount: UFix64) {

    // Local variable for a reference to the ID Table Admin object
    let adminRef: &BloctoTokenStaking.Admin

    prepare(acct: AuthAccount) {
        // borrow a reference to the admin object
        self.adminRef = acct.borrow<&BloctoTokenStaking.Admin>(from: BloctoTokenStaking.StakingAdminStoragePath)
            ?? panic("Could not borrow reference to staking admin")
    }

    execute {
        self.adminRef.setEpochTokenPayout(amount)
    }
}
