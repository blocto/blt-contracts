import BloctoTokenMining from "../../contracts/flow/mining/BloctoTokenMining.cdc"

transaction(name: String, reward: UFix64, divisor: UInt64, capTimes: UInt64) {

    prepare(signer: AuthAccount) {
        let admin = signer
            .borrow<&BloctoTokenMining.Administrator>(from: /storage/bloctoTokenMiningAdmin)
            ?? panic("Signer is not the admin")

        let criteria = BloctoTokenMining.Criteria(reward: reward, divisor: divisor, capTimes: capTimes)

        admin.updateCriteria(name: name, criteria: criteria)
    }
}
