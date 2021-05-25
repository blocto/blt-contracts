import BloctoPass from "../../contracts/flow/token/BloctoPass.cdc"

transaction(address: Address) {

    prepare(signer: AuthAccount) {
        let minter = signer
            .borrow<&BloctoPass.NFTMinter>(from: /storage/bloctoPassMinter)
            ?? panic("Signer is not the admin")

        let blocoPassCollectionRef = getAccount(address).getCapability(/public/bloctoPassCollection)
            .borrow<&{BloctoPass.CollectionPublic}>()
            ?? panic("Could not borrow blocto pass collection public reference")

        minter.mintNFT(recipient: blocoPassCollectionRef, metadata: {})
    }
}
