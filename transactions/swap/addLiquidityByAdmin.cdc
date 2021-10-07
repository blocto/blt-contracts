import FungibleToken from "../../contracts/flow/token/FungibleToken.cdc"
import BloctoToken from "../../contracts/flow/token/BloctoToken.cdc"
import TeleportedTetherToken from "../../contracts/flow/token/TeleportedTetherToken.cdc"
import BltUsdtSwapPair from "../../contracts/flow/swap/BltUsdtSwapPair.cdc"

transaction(token1Amount: UFix64, token2Amount: UFix64) {
  prepare(signer: AuthAccount) {
    let bltVault = signer.borrow<&BloctoToken.Vault>(from: BloctoToken.TokenStoragePath)
        ?? panic("Could not borrow a reference to Vault")
    
    let token1Vault <- bltVault.withdraw(amount: token1Amount) as! @BloctoToken.Vault

    let tetherVault = signer.borrow<&TeleportedTetherToken.Vault>(from: TeleportedTetherToken.TokenStoragePath)
        ?? panic("Could not borrow a reference to Vault")
    
    let token2Vault <- tetherVault.withdraw(amount: token2Amount) as! @TeleportedTetherToken.Vault

    let adminRef = signer.borrow<&BltUsdtSwapPair.Admin>(from: /storage/bltUsdtPairAdmin)
        ?? panic("Could not borrow a reference to Admin")

    let tokenBundle <- BltUsdtSwapPair.createTokenBundle(fromToken1: <- token1Vault, fromToken2: <- token2Vault);
    let liquidityTokenVault <- adminRef.addInitialLiquidity(from: <- tokenBundle)

    if signer.borrow<&BltUsdtSwapPair.Vault>(from: BltUsdtSwapPair.TokenStoragePath) == nil {
      // Create a new swap LP token Vault and put it in storage
      signer.save(<-BltUsdtSwapPair.createEmptyVault(), to: BltUsdtSwapPair.TokenStoragePath)

      // Create a public capability to the Vault that only exposes
      // the deposit function through the Receiver interface
      signer.link<&BltUsdtSwapPair.Vault{FungibleToken.Receiver}>(
        BltUsdtSwapPair.TokenPublicReceiverPath,
        target: BltUsdtSwapPair.TokenStoragePath
      )

      // Create a public capability to the Vault that only exposes
      // the balance field through the Balance interface
      signer.link<&BltUsdtSwapPair.Vault{FungibleToken.Balance}>(
        BltUsdtSwapPair.TokenPublicBalancePath,
        target: BltUsdtSwapPair.TokenStoragePath
      )
    }

    let liquidityTokenRef = signer.borrow<&BltUsdtSwapPair.Vault>(from: BltUsdtSwapPair.TokenStoragePath)
        ?? panic("Could not borrow a reference to Vault")

    liquidityTokenRef.deposit(from: <- liquidityTokenVault)
  }
}
 