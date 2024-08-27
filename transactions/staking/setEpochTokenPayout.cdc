import "BloctoTokenStaking"

transaction(amount: UFix64) {

    // Local variable for a reference to the ID Table Admin object
    let adminRef: auth(BloctoTokenStaking.AdminEntitlement) &BloctoTokenStaking.Admin

    prepare(acct: auth(BorrowValue) &Account) {
        // borrow a reference to the admin object
        self.adminRef = acct.storage.borrow<auth(BloctoTokenStaking.AdminEntitlement) &BloctoTokenStaking.Admin>(from: BloctoTokenStaking.StakingAdminStoragePath)
            ?? panic("Could not borrow reference to staking admin")
    }

    execute {
        self.adminRef.setEpochTokenPayout(amount)
    }
}
