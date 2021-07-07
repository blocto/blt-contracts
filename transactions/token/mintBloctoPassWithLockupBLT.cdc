import BloctoToken from "../../contracts/flow/token/BloctoToken.cdc"
import NonFungibleToken from "../../contracts/flow/token/NonFungibleToken.cdc"
import BloctoPass from "../../contracts/flow/token/BloctoPass.cdc"

transaction(address: Address, amount: UFix64, unlockTime: UFix64) {

    prepare(signer: AuthAccount) {
        let minter = signer
            .borrow<&BloctoPass.NFTMinter>(from: /storage/bloctoPassMinter)
            ?? panic("Signer is not the admin")

        let nftCollectionRef = getAccount(address).getCapability(/public/bloctoPassCollection)
            .borrow<&{NonFungibleToken.CollectionPublic, BloctoPass.CollectionPublic}>()
            ?? panic("Could not borrow blocto pass collection public reference")

        let bltVaultRef = signer
            .borrow<&BloctoToken.Vault>(from: BloctoToken.TokenStoragePath)
            ?? panic("Cannot get BLT vault reference")
        
        let bltVault <- bltVaultRef.withdraw(amount: amount)

        let metadata: {String: String} = {
            "origin": "Private Sale"
        }

        let lockupSchedule: {UFix64: UFix64} = {
            UFix64(0.0): amount,
            unlockTime - 300.0: UFix64(amount / 2.0),
            unlockTime: UFix64(0.0)
        }

        minter.mintNFTWithCustomLockup(
            recipient: nftCollectionRef,
            metadata: metadata,
            vault: <- bltVault,
            lockupSchedule: lockupSchedule
        )
    }
}
