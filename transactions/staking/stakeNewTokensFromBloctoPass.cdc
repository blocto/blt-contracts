import FungibleToken from "../../contracts/flow/token/FungibleToken.cdc"
import BloctoToken from "../../contracts/flow/token/BloctoToken.cdc"
import BloctoPass from "../../contracts/flow/token/BloctoPass.cdc"

transaction(amount: UFix64) {

    // The private reference to user's BloctoPass
    let bloctoPassRef: &BloctoPass.NFT

    prepare(signer: AuthAccount) {

        // Get a reference to the signer's BloctoPass
        let bloctoPassCollectionRef = signer.borrow<&BloctoPass.Collection>(from: /storage/bloctoPassCollection)
			?? panic("Could not borrow reference to the owner's BloctoPass collection!")

        let ids = bloctoPassCollectionRef.getIDs()

        // Get a reference to the 
        self.bloctoPassRef = bloctoPassCollectionRef.borrowBloctoPassPrivate(id: ids[0])
    }

    execute {
        // Perform staking action
        self.bloctoPassRef.stakeNewTokens(amount: amount)
    }
}