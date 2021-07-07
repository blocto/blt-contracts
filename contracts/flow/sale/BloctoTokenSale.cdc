/*

    BloctoTokenSale

    The BloctoToken Sale contract is used for 
    BLT token community sale. Qualified purchasers
    can purchase with tUSDT (Teleported Tether) to get
    BLTs at the same price and lock-up terms as private sale

 */
 
import FungibleToken from "../token/FungibleToken.cdc"
import NonFungibleToken from "../token/NonFungibleToken.cdc"
import BloctoToken from "../token/BloctoToken.cdc"
import BloctoPass from "../token/BloctoPass.cdc"
import TeleportedTetherToken from "../token/TeleportedTetherToken.cdc"

pub contract BloctoTokenSale {

    /****** Sale Events ******/

    pub event Purchased(address: Address, amount: UFix64)

    pub event Distributed(address: Address, tusdtAmount: UFix64, bltAmount: UFix64)

    pub event Refunded(address: Address, amount: UFix64)

    /****** Sale Enums ******/

    pub enum PurchaseState: UInt8 {
        pub case initial
        pub case distributed
        pub case refunded
    }

    // BLT token price (tUSDT per BLT)
    pub var price: UFix64

    // BLT IEO/IDO date, used for lockup terms
    pub var saleDate: UFix64

    // BLT communitu sale purchase cap (in tUSDT)
    pub var personalCap: UFix64

    // All purchase records
    pub var purchases: {Address: PurchaseInfo}

    // BLT holder vault
    access(contract) let bltVault: @BloctoToken.Vault

    // tUSDT holder vault
    access(contract) let tusdtVault: @TeleportedTetherToken.Vault

    /// Paths for storing sale resources
    pub let SaleAdminStoragePath: StoragePath

    pub struct PurchaseInfo {
        // Purchaser address
        pub let address: Address

        // Purchase amount in tUSDT
        pub let amount: UFix64

        // Random queue position
        pub let queuePosition: UInt64

        // State of the purchase
        pub(set) var state: PurchaseState

        init(
            address: Address,
            amount: UFix64,
        ) {
            self.address = address
            self.amount = amount
            self.queuePosition = unsafeRandom() % 1_000_000
            self.state = PurchaseState.initial
        }
    }

    // BLT purchase method
    // User pays tUSDT and get a BloctoPass NFT with lockup terms
    // Note that "address" can potentially be faked, but there's no incentive doing so
    pub fun purchase(from: @TeleportedTetherToken.Vault, address: Address) {
        pre {
            self.purchases[address] == nil: "Already purchased by the same account"
            from.balance <= self.personalCap: "Purchase amount exceeds personal cap"
        }

        let collectionRef = getAccount(address).getCapability(BloctoPass.CollectionPublicPath)
            .borrow<&{NonFungibleToken.CollectionPublic}>()
            ?? panic("Could not borrow blocto pass collection public reference")

        // Make sure user does not already have a BloctoPass
        assert (
            collectionRef.getIDs().length == 0,
            message: "User already has a BloctoPass"
        )

        let amount = from.balance
        self.tusdtVault.deposit(from: <- from)

        self.purchases[address] = PurchaseInfo(address: address, amount: amount)

        emit Purchased(address: address, amount: amount)
    }

    // Get all purchaser addresses
    pub fun getPurchasers(): [Address] {
        return self.purchases.keys
    }

    // Get all purchase records
    pub fun getPurchases(): {Address: PurchaseInfo} {
        return self.purchases
    }

    // Get purchase record from an address
    pub fun getPurchase(address: Address): PurchaseInfo? {
        return self.purchases[address]
    }

    pub fun getBltVaultBalance(): UFix64 {
        return self.bltVault.balance
    }

    pub fun getTusdtVaultBalance(): UFix64 {
        return self.tusdtVault.balance
    }

    pub resource Admin {
        pub fun distribute(address: Address) {
            pre {
                BloctoTokenSale.purchases[address] != nil: "Cannot find purchase record for the address"
                BloctoTokenSale.purchases[address]?.state == PurchaseState.initial: "Already distributed or refunded"
            }

            let collectionRef = getAccount(address).getCapability(BloctoPass.CollectionPublicPath)
                .borrow<&{NonFungibleToken.CollectionPublic}>()
                ?? panic("Could not borrow blocto pass collection public reference")

            // Make sure user does not already have a BloctoPass
            assert (
                collectionRef.getIDs().length == 0,
                message: "User already has a BloctoPass"
            )

            let purchaseInfo = BloctoTokenSale.purchases[address]
                ?? panic("Count not get purchase info for the address")
        
            let minterRef = BloctoTokenSale.account.borrow<&BloctoPass.NFTMinter>(from: BloctoPass.MinterStoragePath)
                ?? panic("Could not borrow reference to the BloctoPass minter!")

            let bltAmount = purchaseInfo.amount / BloctoTokenSale.price
            let bltVault <- BloctoTokenSale.bltVault.withdraw(amount: bltAmount)

            let metadata = {
                "origin": "Community Sale"
            }

            let months = 30.0 * 24.0 * 60.0 * 60.0 // seconds
            let lockupSchedule = {
                0.0                                      : bltAmount,
                BloctoTokenSale.saleDate                 : bltAmount,
                BloctoTokenSale.saleDate + 6.0 * months  : bltAmount * 17.0 / 18.0,
                BloctoTokenSale.saleDate + 7.0 * months  : bltAmount * 16.0 / 18.0,
                BloctoTokenSale.saleDate + 8.0 * months  : bltAmount * 15.0 / 18.0,
                BloctoTokenSale.saleDate + 9.0 * months  : bltAmount * 14.0 / 18.0,
                BloctoTokenSale.saleDate + 10.0 * months : bltAmount * 13.0 / 18.0,
                BloctoTokenSale.saleDate + 11.0 * months : bltAmount * 12.0 / 18.0,
                BloctoTokenSale.saleDate + 12.0 * months : bltAmount * 11.0 / 18.0,
                BloctoTokenSale.saleDate + 13.0 * months : bltAmount * 10.0 / 18.0,
                BloctoTokenSale.saleDate + 14.0 * months : bltAmount * 9.0 / 18.0,
                BloctoTokenSale.saleDate + 15.0 * months : bltAmount * 8.0 / 18.0,
                BloctoTokenSale.saleDate + 16.0 * months : bltAmount * 7.0 / 18.0,
                BloctoTokenSale.saleDate + 17.0 * months : bltAmount * 6.0 / 18.0,
                BloctoTokenSale.saleDate + 18.0 * months : bltAmount * 5.0 / 18.0,
                BloctoTokenSale.saleDate + 19.0 * months : bltAmount * 4.0 / 18.0,
                BloctoTokenSale.saleDate + 20.0 * months : bltAmount * 3.0 / 18.0,
                BloctoTokenSale.saleDate + 21.0 * months : bltAmount * 2.0 / 18.0,
                BloctoTokenSale.saleDate + 22.0 * months : bltAmount * 1.0 / 18.0,
                BloctoTokenSale.saleDate + 23.0 * months : 0.0
            }

            minterRef.mintNFTWithLockup(
                recipient: collectionRef,
                metadata: metadata,
                vault: <- bltVault,
                lockupSchedule: lockupSchedule
            )

            // Set the state of the purchase to DISTRIBUTED
            purchaseInfo.state = PurchaseState.distributed
            BloctoTokenSale.purchases[address] = purchaseInfo

            emit Distributed(address: address, tusdtAmount: purchaseInfo.amount, bltAmount: bltAmount)
        }

        pub fun refund(address: Address) {
            pre {
                BloctoTokenSale.purchases[address] != nil: "Cannot find purchase record for the address"
                BloctoTokenSale.purchases[address]?.state == PurchaseState.initial: "Already distributed or refunded"
            }

            let receiverRef = getAccount(address).getCapability(TeleportedTetherToken.TokenPublicReceiverPath)
                .borrow<&{FungibleToken.Receiver}>()
                ?? panic("Could not borrow tUSDT vault receiver public reference")

            let purchaseInfo = BloctoTokenSale.purchases[address]
                ?? panic("Count not get purchase info for the address")

            let tusdtVault <- BloctoTokenSale.tusdtVault.withdraw(amount: purchaseInfo.amount)

            receiverRef.deposit(from: <- tusdtVault)

            // Set the state of the purchase to REFUNDED
            purchaseInfo.state = PurchaseState.refunded
            BloctoTokenSale.purchases[address] = purchaseInfo

            emit Refunded(address: address, amount: purchaseInfo.amount)
        }

        pub fun updatePrice(price: UFix64) {
            pre {
                price > 0.0: "Sale price cannot be 0"
            }

            BloctoTokenSale.price = price
        }

        pub fun updateSaleDate(date: UFix64) {
            BloctoTokenSale.saleDate = date
        }

        pub fun updatePersonalCap(personalCap: UFix64) {
            BloctoTokenSale.personalCap = personalCap
        }

        pub fun withdrawBlt(amount: UFix64): @FungibleToken.Vault {
            return <- BloctoTokenSale.bltVault.withdraw(amount: amount)
        }

        pub fun withdrawTusdt(amount: UFix64): @FungibleToken.Vault {
            return <- BloctoTokenSale.tusdtVault.withdraw(amount: amount)
        }

        pub fun depositBlt(from: @FungibleToken.Vault) {
            BloctoTokenSale.bltVault.deposit(from: <- from)
        }

        pub fun depositTusdt(from: @FungibleToken.Vault) {
            BloctoTokenSale.tusdtVault.deposit(from: <- from)
        }
    }

    init() {
        // 1 BLT = 0.1 tUSDT
        self.price = 0.1

        // Thursday, July 15, 2021 8:00:00 AM GMT
        self.saleDate = 1626336000.0

        // Each user can purchase at most 1000 tUSDT worth of BLT
        self.personalCap = 1000.0

        self.purchases = {}
        self.SaleAdminStoragePath = /storage/bloctoTokenSaleAdmin

        self.bltVault <- BloctoToken.createEmptyVault() as! @BloctoToken.Vault
        self.tusdtVault <- TeleportedTetherToken.createEmptyVault() as! @TeleportedTetherToken.Vault

        let admin <- create Admin()
        self.account.save(<- admin, to: self.SaleAdminStoragePath)
    }
}
