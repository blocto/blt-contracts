import "FungibleToken"
import "BloctoToken"
import "BloctoPass"

transaction(amount: UFix64, index: Int) {

  // The Vault resource that holds the tokens that are being transferred
  let vaultRef: auth(FungibleToken.Withdraw) &BloctoToken.Vault

  // The private reference to user's BloctoPass
  let bloctoPassRef: auth(BloctoPass.BloctoPassPrivateEntitlement) &BloctoPass.NFT

  prepare(account: auth(BorrowValue) &Account) {
    // Get a reference to the account's stored vault
    self.vaultRef = account.storage.borrow<auth(FungibleToken.Withdraw) &BloctoToken.Vault>(from: BloctoToken.TokenStoragePath)
      ?? panic("Could not borrow reference to the owner's Vault!")

    // Get a reference to the account's BloctoPass
    let bloctoPassCollectionRef = account.storage.borrow<auth(BloctoPass.CollectionPrivateEntitlement) &BloctoPass.Collection>(from: /storage/bloctoPassCollection)
      ?? panic("Could not borrow reference to the owner's BloctoPass collection!")

    let ids = bloctoPassCollectionRef.getIDs()

    // Get a reference to the BloctoPass
    self.bloctoPassRef = bloctoPassCollectionRef.borrowBloctoPassPrivate(id: ids[index])
  }

  execute {
    let lockedBalance = self.bloctoPassRef.getIdleBalance()

    if amount <= lockedBalance {
      self.bloctoPassRef.stakeNewTokens(amount: amount)
    } else if ((amount - lockedBalance) <= self.vaultRef.balance) {
      self.bloctoPassRef.deposit(from: <-self.vaultRef.withdraw(amount: amount - lockedBalance))
      self.bloctoPassRef.stakeNewTokens(amount: amount)
    } else {
      panic("Not enough tokens to stake!")
    }
  }
}