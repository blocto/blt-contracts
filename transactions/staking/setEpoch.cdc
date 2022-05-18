transaction(epoch: UInt64) {
    prepare(acct: AuthAccount) {
        acct.load<UInt64>(from: /storage/bloctoTokenStakingEpoch)
        acct.save<UInt64>(epoch, to: /storage/bloctoTokenStakingEpoch)
    }
}
