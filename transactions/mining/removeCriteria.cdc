import BloctoTokenMining from "../../contracts/flow/mining/BloctoTokenMining.cdc"

transaction(name: String) {

    prepare(signer: AuthAccount) {
        let admin = signer
            .borrow<&BloctoTokenMining.Administrator>(from: /storage/bloctoTokenMiningAdmin)
            ?? panic("Signer is not the admin")

        admin.updateCriteria(name: name, criteria: nil)
    }
}
