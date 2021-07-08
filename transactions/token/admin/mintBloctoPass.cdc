import NonFungibleToken from "../../../contracts/flow/token/NonFungibleToken.cdc"
import BloctoPass from "../../../contracts/flow/token/BloctoPass.cdc"

transaction(address: Address) {

    prepare(signer: AuthAccount) {
        let minter = signer
            .borrow<&BloctoPass.NFTMinter>(from: BloctoPass.MinterStoragePath)
            ?? panic("Signer is not the admin")

        let nftCollectionRef = getAccount(address).getCapability(BloctoPass.CollectionPublicPath)
            .borrow<&{NonFungibleToken.CollectionPublic}>()
            ?? panic("Could not borrow blocto pass collection public reference")

        minter.mintNFT(recipient: nftCollectionRef, metadata: {})
    }
}
