/*

    BloctoTokenSale

    The BloctoToken Sale contract is used for 
    BLT token community sale. Qualified purchasers
    can purchase with tUSDT (Teleported Tether) to get
    BLTs at the same price and lock-up terms as private sale

 */
 
import FungibleToken from "../token/FungibleToken.cdc"
import BloctoToken from "../token/BloctoToken.cdc"
import BloctoPass from "../token/BloctoPass.cdc"
import TeleportedTetherToken from "../token/TeleportedTetherToken"

pub contract BloctoTokenSale {
    // BLT token price ($tUSDT per BLT)
    pub var price: UFix64

    // BLT IEO/IDO date, used for lockup terms
    pub var saleDate: UFix64

    // BLT holder vault
    access(contract) let bltVault: @BloctoToken.Vault

    // tUSDT holder vault
    access(contract) let tusdtVault: @TeleportedTetherToken.Vault

    // BLT purchase method
    // User pays tUSDT and get a BloctoPass NFT with lockup terms
    pub fun purchase(from: @TeleportedTetherToken.Vault, recipient: &{NonFungibleToken.CollectionPublic}) {
        pre {
            recipient.getIDs().length == 0: "User already has a BloctoPass"
        }

        let bltAmount = from.balance / price

        let bltVault <- self.bltVault.withdraw(amount: bltAmount)
        self.tusdtVault.deposit(from: from)
        
        let minterRef = self.account.borrow<&BloctoPass.NFTMinter>(from: /storage/bloctoPassMinter)
			?? panic("Could not borrow reference to the BloctoPass minter!")

        let metadata = {
            "type": "Blocto Community Sale"
        }

        // TODO: Setup proper lockup schedule
        let lockupSchedule = {
            0.0: 0.0
        }

        minterRef.mintNFTWithLockup(
            recipient: recipient,
            metadata: metadata,
            vault: <- bltVault,
            lockupSchedule: lockupSchedule
        )
    }

    pub resource Admin {
        pub fun updatePrice(price: UFix64) {
            pre {
                price > 0.0: "Sale price cannot be 0"
            }

            BloctoTokenSale.price = price
        }

        pub fun updateSaleDate(date: UFix64) {
            BloctoTokenSale.saleDate = date
        }

        pub fun withdrawBlt(amount: UFix64): : @FungibleToken.Vault {
            return <- BloctoTokenSale.bltVault.withdraw(amount: amount)
        }

        pub fun withdrawTusdt(amount: UFix64): : @FungibleToken.Vault {
            return <- BloctoTokenSale.tusdtVault.withdraw(amount: amount)
        }

        pub fun depositBlt(from: @FungibleToken.Vault) {
            BloctoTokenSale.bltVault.deposit(from: <- from)
        }
    }

    init() {
        // 1 BLT = 0.1 tUSDT
        self.price = 0.1

        self.bltVault <- BloctoToken.createEmptyVault() as! @BloctoToken.Vault
        self.tusdtVault <- TeleportedTetherToken.createEmptyVault() as! @TeleportedTetherToken.Vault

        let admin <- create Admin()
        self.account.save(<- admin, to: /storage/bloctoTokenSaleAdmin)
    }
}
