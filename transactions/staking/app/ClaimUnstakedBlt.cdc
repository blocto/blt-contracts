import "BloctoToken"
import "BloctoPass"

transaction(amount: UFix64, index: Int) {

  // The Vault resource that holds the tokens that are being transferred
  let vaultRef: &BloctoToken.Vault

  // The private reference to user's BloctoPass
  let bloctoPassRef: auth(BloctoPass.BloctoPassPrivateEntitlement) &BloctoPass.NFT

  prepare(account: auth(BorrowValue, Capabilities) &Account) {
    // Get a reference to the account's stored vault
    self.vaultRef = account.storage.borrow<&BloctoToken.Vault>(from: BloctoToken.TokenStoragePath)
      ?? panic("Could not borrow reference to the owner's Vault!")

    // Get a reference to the account's BloctoPass
    let bloctoPassCollectionRef = account.storage.borrow<auth(BloctoPass.CollectionPrivateEntitlement) &BloctoPass.Collection>(from: /storage/bloctoPassCollection)
      ?? panic("Could not borrow reference to the owner's BloctoPass collection!")

    let ids = bloctoPassCollectionRef.getIDs()

    // Get a reference to the BloctoPass
    self.bloctoPassRef = bloctoPassCollectionRef.borrowBloctoPassPrivate(id: ids[index])
  }

  execute {
    self.bloctoPassRef.withdrawUnstakedTokens(amount: amount)

    // Unlock as much as possible
    let limit = self.bloctoPassRef.getTotalBalance() - self.bloctoPassRef.getLockupAmount()
    let max = limit > amount ? amount : limit

    if (max > 0.0) {
        self.vaultRef.deposit(from: <-self.bloctoPassRef.withdraw(amount: max))
    }
  } 
}