import BloctoToken from "../../../contracts/flow/token/BloctoToken.cdc"
import NonFungibleToken from "../../../contracts/flow/token/NonFungibleToken.cdc"
import BloctoPass from "../../../contracts/flow/token/BloctoPass.cdc"

transaction(address: Address, amount: UFix64, lockupScheduleId: Int) {

    prepare(signer: AuthAccount) {
        let minter = signer
            .borrow<&BloctoPass.NFTMinter>(from: BloctoPass.MinterStoragePath)
            ?? panic("Signer is not the admin")

        let nftCollectionRef = getAccount(address).getCapability(BloctoPass.CollectionPublicPath)
            .borrow<&{NonFungibleToken.CollectionPublic, BloctoPass.CollectionPublic}>()
            ?? panic("Could not borrow blocto pass collection public reference")

        let bltVaultRef = signer
            .borrow<&BloctoToken.Vault>(from: BloctoToken.TokenStoragePath)
            ?? panic("Cannot get BLT vault reference")
        
        let bltVault <- bltVaultRef.withdraw(amount: amount)

        let metadata: {String: String} = {
            "origin": "Private Sale"
        }

        minter.mintNFTWithPredefinedLockup(
            recipient: nftCollectionRef,
            metadata: metadata,
            vault: <- bltVault,
            lockupScheduleId: lockupScheduleId
        )
    }
}
