import "BloctoToken"

transaction {
    prepare(stakingAdmin: auth(Storage) &Account) {
        destroy stakingAdmin.storage.load<@BloctoToken.Minter>(from: /storage/bloctoTokenStakingMinter)
    }
}
