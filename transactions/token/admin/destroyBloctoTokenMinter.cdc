import BloctoToken from "../../../contracts/flow/token/BloctoToken.cdc"

transaction {
    prepare(stakingAdmin: AuthAccount) {
        destroy stakingAdmin.load<@BloctoToken.Minter>(from: /storage/bloctoTokenStakingMinter)
    }
}
