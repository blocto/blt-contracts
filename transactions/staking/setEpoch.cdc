transaction(epoch: UInt64) {
    prepare(acct: auth(BorrowValue, SaveValue) &Account) {
        // acct.load<UInt64>(from: /storage/bloctoTokenStakingEpoch)
        acct.storage.save(epoch, to: /storage/bloctoTokenStakingEpoch)        
    }
}
