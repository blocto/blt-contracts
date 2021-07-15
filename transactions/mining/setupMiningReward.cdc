import BloctoTokenMining from "../../contracts/flow/mining/BloctoTokenMining.cdc"

transaction {

    prepare(signer: AuthAccount) {
        if signer.borrow<&BloctoTokenMining.MiningReward>(from: BloctoTokenMining.MiningRewardStoragePath) == nil {

            let miningReward <- BloctoTokenMining.createEmptyMiningReward()

            signer.save(<-miningReward, to: BloctoTokenMining.MiningRewardStoragePath)

            signer.link<&{BloctoTokenMining.MiningRewardPublic}>(
                BloctoTokenMining.MiningRewardPublicPath,
                target: BloctoTokenMining.MiningRewardStoragePath)
        }
    }
}