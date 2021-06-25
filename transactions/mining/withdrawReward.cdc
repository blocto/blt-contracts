import BloctoTokenMining from "../../contracts/flow/mining/BloctoTokenMining.cdc"
import BloctoToken from "../../contracts/flow/token/BloctoToken.cdc"

transaction {

    prepare(signer: AuthAccount) {
        let vaultRef = signer.borrow<&BloctoToken.Vault>(from: BloctoToken.TokenStoragePath)
            ?? panic("Could not borrow reference to the owner's Vault!")

        let miningRewardRef = signer.borrow<&BloctoTokenMining.MiningReward>(from: BloctoTokenMining.MiningRewardStoragePath)
            ?? panic("Could not borrow reference to the owner's mining reward!")

        let rewardVault <- miningRewardRef.withdraw()
        vaultRef.deposit(from: <- rewardVault)
    }
}