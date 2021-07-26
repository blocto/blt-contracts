import FungibleToken from "../../../contracts/flow/token/FungibleToken.cdc"
import NonFungibleToken from "../../../contracts/flow/token/NonFungibleToken.cdc"
import BloctoToken from "../../../contracts/flow/token/BloctoToken.cdc"
import BloctoPass from "../../../contracts/flow/token/BloctoPass.cdc"

transaction(address: Address, amount: UFix64, startDate: UFix64) {

    prepare(signer: AuthAccount) {
        let minter = signer
            .borrow<&BloctoPass.NFTMinter>(from: BloctoPass.MinterStoragePath)
            ?? panic("Signer is not the admin")

        let nftCollectionRef = getAccount(address).getCapability(BloctoPass.CollectionPublicPath)
            .borrow<&{NonFungibleToken.CollectionPublic, BloctoPass.CollectionPublic}>()
            ?? panic("Could not borrow blocto pass collection public reference")

        // Make sure user does not already have a BloctoPass
        assert (
            nftCollectionRef.getIDs().length == 0,
            message: "User already has a BloctoPass"
        )

        let bltVaultRef = signer
            .borrow<&BloctoToken.Vault>(from: BloctoToken.TokenStoragePath)
            ?? panic("Cannot get BLT vault reference")
        
        let bltVault <- bltVaultRef.withdraw(amount: amount)

        let metadata: {String: String} = {
            "origin": "Private Sale"
        }

        let months = 30.0 * 24.0 * 60.0 * 60.0 // seconds
        let lockupSchedule = {
            0.0                       : 1.0,
            startDate                 : 1.0,
            startDate + 6.0 * months  : 17.0 / 18.0,
            startDate + 7.0 * months  : 16.0 / 18.0,
            startDate + 8.0 * months  : 15.0 / 18.0,
            startDate + 9.0 * months  : 14.0 / 18.0,
            startDate + 10.0 * months : 13.0 / 18.0,
            startDate + 11.0 * months : 12.0 / 18.0,
            startDate + 12.0 * months : 11.0 / 18.0,
            startDate + 13.0 * months : 10.0 / 18.0,
            startDate + 14.0 * months : 9.0 / 18.0,
            startDate + 15.0 * months : 8.0 / 18.0,
            startDate + 16.0 * months : 7.0 / 18.0,
            startDate + 17.0 * months : 6.0 / 18.0,
            startDate + 18.0 * months : 5.0 / 18.0,
            startDate + 19.0 * months : 4.0 / 18.0,
            startDate + 20.0 * months : 3.0 / 18.0,
            startDate + 21.0 * months : 2.0 / 18.0,
            startDate + 22.0 * months : 1.0 / 18.0,
            startDate + 23.0 * months : 0.0
        }

        minter.mintNFTWithCustomLockup(
            recipient: nftCollectionRef,
            metadata: metadata,
            vault: <- bltVault,
            lockupSchedule: lockupSchedule
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
