// This is the implementation of BloctoPass, the Blocto Non-Fungible Token
// that is used in-conjunction with BLT, the Blocto Fungible Token

import FungibleToken from "./FungibleToken.cdc"
import NonFungibleToken from "./NonFungibleToken.cdc"
import BloctoToken from "./BloctoToken.cdc"
import BloctoTokenStaking from "../staking/BloctoTokenStaking.cdc"

pub contract BloctoPass: NonFungibleToken {

    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)

    pub resource interface BloctoPassPrivate {

    }

    pub resource interface BloctoPassPublic {
        pub fun getVipTier(): UInt64
        pub fun getLockupSchedule(): {UFix64: UFix64}
        pub fun getLockupAmountAtTimestamp(timestamp: UFix64): UFix64
        pub fun getIdleBalance(): UFix64
        pub fun getTotalBalance(): UFix64
    }

    pub resource NFT:
        NonFungibleToken.INFT,
        FungibleToken.Provider,
        FungibleToken.Receiver,
        BloctoPassPrivate,
        BloctoPassPublic
    {
        // BLT holder vault
        pub let vault: @BloctoToken.Vault

        pub let staker: @BloctoTokenStaking.Staker

        pub let id: UInt64

        pub var metadata: {String: String}

        // Defines how much BloctoToken must remain in the BloctoPass on different times
        pub let lockupSchedule: {UFix64: UFix64}

        init(
            initID: UInt64,
            metadata: {String: String},
            vault: @FungibleToken.Vault,
            lockupSchedule: {UFix64: UFix64}
        ) {
            self.id = initID
            self.metadata = metadata
            self.vault <- vault as! @BloctoToken.Vault
            self.staker <- BloctoTokenStaking.addStakerRecord(id: initID)
            self.lockupSchedule = lockupSchedule
        }

        pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
            post {
                self.getTotalBalance() >= self.getLockupAmountAtTimestamp(timestamp: getCurrentBlock().timestamp):
                    "Cannot withdraw locked-up BloctoTokens"
            }

            return <- self.vault.withdraw(amount: amount)
        }

        pub fun deposit(from: @FungibleToken.Vault) {
            self.vault.deposit(from: <- from)
        }

        pub fun getVipTier(): UInt64 {
            return 0
        }

        pub fun getLockupSchedule(): {UFix64: UFix64} {
            return self.lockupSchedule
        }

        pub fun getLockupAmountAtTimestamp(timestamp: UFix64): UFix64 {
            let keys = self.lockupSchedule.keys
            let currentTimestamp = getCurrentBlock().timestamp
            var closestTimestamp = 0.0
            var lockupAmount = 0.0

            for key in keys {
                if currentTimestamp >= key && key > closestTimestamp {
                    lockupAmount = self.lockupSchedule[key]!
                    closestTimestamp = key
                }
            }

            return lockupAmount
        }

        pub fun getIdleBalance(): UFix64 {
            return self.vault.balance
        }

        pub fun getTotalBalance(): UFix64 {
            return self.getIdleBalance() + BloctoTokenStaking.StakerInfo(self.id).totalTokensInRecord()
        }

        destroy() {
            destroy self.vault
            destroy self.staker
        }
    }

    // CollectionPublic is a custom interface that allows us to
    // access the public fields and methods for our BloctoPass Collection
    pub resource interface CollectionPublic {
        pub fun borrowBloctoPass(id: UInt64): &BloctoPass.NFT
        pub fun depositBloctoToken(from: @FungibleToken.Vault, id: UInt64)
    }

    pub resource Collection:
        NonFungibleToken.Provider,
        NonFungibleToken.Receiver,
        NonFungibleToken.CollectionPublic,
        CollectionPublic
    {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        // withdrawal is disabled during lockup period
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            // Reject all calls
            panic("NFT withdrawal is disabled")

            // let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            // emit Withdraw(id: token.id, from: self.owner?.address)

            // return <-token
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @BloctoPass.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }

        // borrowBloctoPass gets an authorized reference to an NFT in the collection
        // and returns it to the caller as a reference to the BloctoPass.NFT
        pub fun borrowBloctoPass(id: UInt64): &BloctoPass.NFT {
            let bloctoPassRef = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
            return bloctoPassRef as! &BloctoPass.NFT
        }

        // depositBloctoToken deposits BloctoToken to a vault of BloctoPass.NFT
        pub fun depositBloctoToken(from: @FungibleToken.Vault, id: UInt64) {
            let token <- (self.ownedNFTs.remove(key: id) ?? panic("missing NFT")) as! @BloctoPass.NFT
            token.deposit(from: <- from)

            let oldToken <- self.ownedNFTs[id] <- token
            destroy oldToken
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    // Resource that an admin or something similar would own to be
    // able to mint new NFTs
    //
    pub resource NFTMinter {

        // mintNFT mints a new NFT with a new ID
        // and deposit it in the recipients collection using their collection reference
        pub fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, metadata: {String: String}) {
            self.mintNFTWithLockup(
                recipient: recipient,
                metadata: metadata,
                vault: <- BloctoToken.createEmptyVault(),
                lockupSchedule: {0.0: 0.0}
            )
        }

        pub fun mintNFTWithLockup(
            recipient: &{NonFungibleToken.CollectionPublic},
            metadata: {String: String},
            vault: @FungibleToken.Vault,
            lockupSchedule: {UFix64: UFix64}
        ) {

            // create a new NFT
            var newNFT <- create NFT(
                initID: BloctoPass.totalSupply,
                metadata: metadata,
                vault: <- vault,
                lockupSchedule: lockupSchedule
            )

            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-newNFT)

            BloctoPass.totalSupply = BloctoPass.totalSupply + UInt64(1)
        }
    }

    init() {
        // Initialize the total supply
        self.totalSupply = 0

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: /storage/bloctoPassCollection)

        // create a public capability for the collection
        self.account.link<&{NonFungibleToken.CollectionPublic, BloctoPass.CollectionPublic}>(
            /public/bloctoPassCollection,
            target: /storage/bloctoPassCollection
        )

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: /storage/bloctoPassMinter)

        emit ContractInitialized()
    }
}
