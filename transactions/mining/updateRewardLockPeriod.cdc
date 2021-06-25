import BloctoTokenMining from "../../contracts/flow/mining/BloctoTokenMining.cdc"

transaction(rewardLockPeriod: UInt64) {
    prepare(signer: AuthAccount) {
        let admin = signer
            .borrow<&BloctoTokenMining.Administrator>(from: /storage/bloctoTokenMiningAdmin)
            ?? panic("Signer is not the admin")

        admin.updateRewardLockPeriod(rewardLockPeriod)
    }
}
