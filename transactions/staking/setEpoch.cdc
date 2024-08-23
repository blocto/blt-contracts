import "BloctoTokenStaking"
transaction(epoch: UInt64) {
    prepare(acct: auth(Storage, SaveValue) &Account) {
        acct.storage.load<UInt64>(from: /storage/bloctoTokenStakingEpoch)
        acct.storage.save(epoch, to: /storage/bloctoTokenStakingEpoch)        
    }
}

