import BloctoTokenMining from "../../contracts/flow/mining/BloctoTokenMining.cdc"

transaction(rewardCap: UFix64) {
    prepare(signer: AuthAccount) {
        let admin = signer
            .borrow<&BloctoTokenMining.Administrator>(from: /storage/bloctoTokenMiningAdmin)
            ?? panic("Signer is not the admin")

        admin.updateRewardCap(rewardCap)
    }
}
