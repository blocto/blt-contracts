import BloctoTokenMining from "../../contracts/flow/mining/BloctoTokenMining.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        let admin = signer
            .borrow<&BloctoTokenMining.Administrator>(from: /storage/bloctoTokenMiningAdmin)
            ?? panic("Signer is not the admin")

        admin.startCollecting()
    }
}
