import "BloctoTokenStaking"

// This transaction effectively ends the epoch and starts a new one.
//
// It combines the end_staking and move_tokens transactions
// which ends the staking auction, which refunds nodes with insufficient stake
// and moves tokens between buckets

transaction {

    // Local variable for a reference to the ID Table Admin object
    let adminRef: auth(BloctoTokenStaking.AdminEntitlement) &BloctoTokenStaking.Admin

    prepare(acct: auth(BorrowValue) &Account) {
        // borrow a reference to the admin object
        self.adminRef = acct.storage.borrow<auth(BloctoTokenStaking.AdminEntitlement) &BloctoTokenStaking.Admin>(from: BloctoTokenStaking.StakingAdminStoragePath)
            ?? panic("Could not borrow reference to staking admin")
    }

    execute {
        self.adminRef.endStakingAuction()
        self.adminRef.payRewards()
        self.adminRef.moveTokens()
        self.adminRef.startStakingAuction()
    }
}
