import BloctoTokenMining from "../../contracts/flow/mining/BloctoTokenMining.cdc"

transaction(address: Address) {

    prepare(signer: AuthAccount) {
        let admin = signer
            .borrow<&BloctoTokenMining.Administrator>(from: /storage/bloctoTokenMiningAdmin)
            ?? panic("Signer is not the admin")

        admin.distributeReward(address: address)
    }
}
