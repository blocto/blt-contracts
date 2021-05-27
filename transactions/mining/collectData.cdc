import BloctoTokenMining from "../../contracts/flow/mining/BloctoTokenMining.cdc"

transaction(address: Address, tx: UFix64, referral: UFix64, assetInCirculation: UFix64) {

    prepare(signer: AuthAccount) {
        let admin = signer
            .borrow<&BloctoTokenMining.Administrator>(from: /storage/bloctoTokenMiningAdmin)
            ?? panic("Signer is not the admin")

        let data = {
            "tx": tx,
            "referral": referral,
            "assetInCirculation": assetInCirculation
        }

        admin.collectData(data, address: address)
    }
}
