import BloctoTokenMining from "../../contracts/flow/mining/BloctoTokenMining.cdc"
import BloctoToken from "../../contracts/flow/token/BloctoToken.cdc"

transaction(address: Address) {

    prepare(signer: AuthAccount, rewardHolder: AuthAccount) {
        let admin = signer
            .borrow<&BloctoTokenMining.Administrator>(from: /storage/bloctoTokenMiningAdmin)
            ?? panic("Signer is not the admin")

        let vault = rewardHolder
            .borrow<&BloctoToken.Vault>(from: BloctoToken.TokenStoragePath)
            ?? panic("Reward holder doens't BloctoToken vault")

        let reward = BloctoTokenMining.computeFinalReward(address: address)
        let rewardVault <- vault.withdraw(amount: reward) as! @BloctoToken.Vault

        admin.distributeReward(address: address, rewardVault: <- rewardVault)
    }
}
