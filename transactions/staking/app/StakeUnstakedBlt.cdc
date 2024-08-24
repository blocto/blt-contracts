import "BloctoPass"

transaction(amount: UFix64, index: Int) {
  // The private reference to user's BloctoPass
  let bloctoPassRef: auth(BloctoPass.BloctoPassPrivateEntitlement) &BloctoPass.NFT

  prepare(account: auth(BorrowValue) &Account) {
    // Get a reference to the account's BloctoPass
    let bloctoPassCollectionRef = account.storage.borrow<auth(BloctoPass.CollectionPrivateEntitlement) &BloctoPass.Collection>(from: /storage/bloctoPassCollection)
      ?? panic("Could not borrow reference to the owner's BloctoPass collection!")

    let ids = bloctoPassCollectionRef.getIDs()

    // Get a reference to the BloctoPass
    self.bloctoPassRef = bloctoPassCollectionRef.borrowBloctoPassPrivate(id: ids[index])
  }

  execute {
    self.bloctoPassRef.stakeUnstakedTokens(amount: amount)
  }
}