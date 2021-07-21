import FungibleToken from "../../../contracts/flow/token/FungibleToken.cdc"
import NonFungibleToken from "../../../contracts/flow/token/NonFungibleToken.cdc"
import BloctoToken from "../../../contracts/flow/token/BloctoToken.cdc"
import BloctoPass from "../../../contracts/flow/token/BloctoPass.cdc"

transaction(address: Address, amount: UFix64) {

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
            lockupScheduleId: 1
        )

        // Get a reference to the signer's stored vault
        let flowVaultRef = signer.borrow<&FungibleToken.Vault>(from: /storage/flowTokenVault)
			?? panic("Could not borrow reference to the owner's Vault!")

        // Get the recipient's public account object
        let recipient = getAccount(address)

        // Get a reference to the recipient's FLOW Receiver
        let receiverRef = recipient.getCapability(/public/flowTokenReceiver)
            .borrow<&{FungibleToken.Receiver}>()
            ?? panic("Could not borrow receiver reference to the recipient's Vault")

        // Deposit the withdrawn tokens in the recipient's receiver
        receiverRef.deposit(from: <-flowVaultRef.withdraw(amount: 0.0001))
    }
}
