// This is the implementation of BloctoPass, the Blocto Non-Fungible Token
// that is used in-conjunction with BLT, the Blocto Fungible Token

import "FungibleToken" 
import "NonFungibleToken"
import "BloctoToken"
import "BloctoTokenStaking" 
import "BloctoPassStamp"

import "ViewResolver"
import "MetadataViews"

access(all)
contract BloctoPass: NonFungibleToken{ 
    // An entitlement for BloctoPassPrivate access
    access(all) entitlement BloctoPassPrivateEntitlement
    // An entitlement for CollectionPrivate access
    access(all) entitlement CollectionPrivateEntitlement
    // An entitlement for MinterPublic access
    access(all) entitlement MinterPublicEntitlement
    // An entitlement for NFTMinter access
    access(all) entitlement NFTMinterEntitlement

    access(all)
    var totalSupply: UInt64
    
    access(all)
    let CollectionStoragePath: StoragePath
    
    access(all)
    let CollectionPublicPath: PublicPath
    
    access(all)
    let MinterStoragePath: StoragePath
    
    access(all)
    let MinterPublicPath: PublicPath
    
    // pre-defined lockup schedules
    // key: timestamp
    // value: percentage of BLT that must remain in the BloctoPass at this timestamp
    access(contract)
    var predefinedLockupSchedules: [{UFix64: UFix64}]
    
    access(all)
    event ContractInitialized()
    
    access(all)
    event Withdraw(id: UInt64, from: Address?)
    
    access(all)
    event Deposit(id: UInt64, to: Address?)
    
    access(all)
    event LockupScheduleDefined(id: Int, lockupSchedule:{ UFix64: UFix64})
    
    access(all)
    event LockupScheduleUpdated(id: Int, lockupSchedule:{ UFix64: UFix64})
    
    access(all)
    resource interface BloctoPassPrivate{ 
        access(BloctoPassPrivateEntitlement)
        fun stakeNewTokens(amount: UFix64): Void
        
        access(BloctoPassPrivateEntitlement)
        fun stakeUnstakedTokens(amount: UFix64)
        
        access(BloctoPassPrivateEntitlement)
        fun stakeRewardedTokens(amount: UFix64)
        
        access(BloctoPassPrivateEntitlement)
        fun requestUnstaking(amount: UFix64)
        
        access(BloctoPassPrivateEntitlement)
        fun unstakeAll()
        
        access(BloctoPassPrivateEntitlement)
        fun withdrawUnstakedTokens(amount: UFix64)
        
        access(BloctoPassPrivateEntitlement)
        fun withdrawRewardedTokens(amount: UFix64)
        
        access(BloctoPassPrivateEntitlement)
        fun withdrawAllUnlockedTokens(): @{FungibleToken.Vault}
        
        access(BloctoPassPrivateEntitlement)
        fun stampBloctoPass(from: @BloctoPassStamp.NFT)
    }
    
    access(all)
    resource interface BloctoPassPublic{ 
        access(all)
        fun getOriginalOwner(): Address?
        
        access(all)
        fun getMetadata():{ String: String}
        
        access(all)
        fun getStamps(): [String]
        
        access(all)
        fun getVipTier(): UInt64
        
        access(all)
        fun getStakingInfo(): BloctoTokenStaking.StakerInfo
        
        access(all)
        fun getLockupSchedule():{ UFix64: UFix64}
        
        access(all)
        fun getLockupAmountAtTimestamp(timestamp: UFix64): UFix64
        
        access(all)
        fun getLockupAmount(): UFix64
        
        access(all)
        fun getIdleBalance(): UFix64

        access(all)
        fun getTotalBalance(): UFix64
    }
    
    access(all)
    resource NFT: NonFungibleToken.NFT, BloctoPassPrivate, BloctoPassPublic { 
        // BLT holder vault
        access(self)
        let vault: @BloctoToken.Vault
        
        // BLT staker handle
        access(self)
        let staker: @BloctoTokenStaking.Staker
        
        // BloctoPass ID
        access(all)
        let id: UInt64
        
        // BloctoPass owner address
        // If the pass is transferred to another user, some perks will be disabled
        access(all)
        let originalOwner: Address?
        
        // BloctoPass metadata
        access(self)
        var metadata:{ String: String}
        
        // BloctoPass usage stamps, including voting records and special events
        access(self)
        var stamps: [String]
        
        // Total amount that's subject to lockup schedule
        access(all)
        let lockupAmount: UFix64
        
        // ID of predefined lockup schedule
        // If lockupScheduleId == nil, use custom lockup schedule instead
        access(all)
        let lockupScheduleId: Int?
        
        // Defines how much BloctoToken must remain in the BloctoPass on different dates
        // key: timestamp
        // value: percentage of BLT that must remain in the BloctoPass at this timestamp
        access(self)
        let lockupSchedule:{ UFix64: UFix64}?

        
        init(initID: UInt64, originalOwner: Address?, metadata:{ String: String}, vault: @{FungibleToken.Vault}, lockupScheduleId: Int?, lockupSchedule:{ UFix64: UFix64}?){ 
            let stakingAdmin = BloctoPass.account.storage.borrow<auth(BloctoTokenStaking.AdminEntitlement) &BloctoTokenStaking.Admin>(from: BloctoTokenStaking.StakingAdminStoragePath) ?? panic("Could not borrow admin reference")
            self.id = initID
            self.originalOwner = originalOwner
            self.metadata = metadata
            self.stamps = []
            self.vault <- vault as! @BloctoToken.Vault
            self.staker <- stakingAdmin.addStakerRecord(id: initID)
            
            // lockup calculations
            self.lockupAmount = self.vault.balance
            self.lockupScheduleId = lockupScheduleId
            self.lockupSchedule = lockupSchedule
        }
        
        access(BloctoPassPrivateEntitlement)
        fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
            post{ 
                self.getTotalBalance() >= self.getLockupAmount():
                    "Cannot withdraw locked-up BLTs"
            }

            return <- self.vault.withdraw(amount: amount)
        }
        
        access(all)
        fun deposit(from: @{FungibleToken.Vault}): Void{ 
            self.vault.deposit(from: <-from)
        }
        
        access(all)
        fun getOriginalOwner(): Address?{ 
            return self.originalOwner
        }
        
        access(all)
        fun getMetadata():{ String: String}{ 
            return self.metadata
        }
        
        access(all)
        fun getStamps(): [String]{ 
            return self.stamps
        }
        
        access(all)
        fun getVipTier(): UInt64{ 
            // Disable VIP tier at launch
            // let stakedAmount = self.getStakingInfo().tokensStaked
            // if stakedAmount >= 1000.0 {
            //     return 1
            // }
            
            // TODO: add more tiers
            return 0
        }
        
        access(all)
        view fun getLockupSchedule():{ UFix64: UFix64}{ 
            if self.lockupScheduleId == nil {
                return self.lockupSchedule ?? {0.0: 0.0}
            }
            return BloctoPass.predefinedLockupSchedules[self.lockupScheduleId!]
        }
        
        access(all)
        fun getStakingInfo(): BloctoTokenStaking.StakerInfo{ 
            return BloctoTokenStaking.StakerInfo(stakerID: self.id)
        }
        
        access(all)
        view fun getLockupAmountAtTimestamp(timestamp: UFix64): UFix64{ 
            if (self.lockupAmount == 0.0) {
                return 0.0
            }
            let lockupSchedule = self.getLockupSchedule()
            let keys = lockupSchedule.keys
            var closestTimestamp = 0.0
            var lockupPercentage = 0.0
            for key in keys {
                if timestamp >= key && key >= closestTimestamp {
                    lockupPercentage = lockupSchedule[key]!
                    closestTimestamp = key
                }
            }
            return lockupPercentage * self.lockupAmount
        }
        
        access(all)
        view fun getLockupAmount(): UFix64{ 
            return self.getLockupAmountAtTimestamp(timestamp: getCurrentBlock().timestamp)
        }
        
        access(all)
        view fun getIdleBalance(): UFix64{ 
            return self.vault.balance
        }
        
        access(all)
        view fun getTotalBalance(): UFix64{ 
            return self.getIdleBalance() + BloctoTokenStaking.StakerInfo(stakerID: self.id).totalTokensInRecord()
        }
        
        // Private staking methods
        access(BloctoPassPrivateEntitlement)
        fun stakeNewTokens(amount: UFix64){ 
            self.staker.stakeNewTokens(<-self.vault.withdraw(amount: amount))
        }
        
        access(BloctoPassPrivateEntitlement)
        fun stakeUnstakedTokens(amount: UFix64){ 
            self.staker.stakeUnstakedTokens(amount: amount)
        }
        
        access(BloctoPassPrivateEntitlement)
        fun stakeRewardedTokens(amount: UFix64){ 
            self.staker.stakeRewardedTokens(amount: amount)
        }
        
        access(BloctoPassPrivateEntitlement)
        fun requestUnstaking(amount: UFix64){ 
            self.staker.requestUnstaking(amount: amount)
        }
        
        access(BloctoPassPrivateEntitlement)
        fun unstakeAll(){ 
            self.staker.unstakeAll()
        }
        
        access(BloctoPassPrivateEntitlement)
        fun withdrawUnstakedTokens(amount: UFix64){ 
            let vault <- self.staker.withdrawUnstakedTokens(amount: amount)
            self.vault.deposit(from: <-vault)
        }
        
        access(BloctoPassPrivateEntitlement)
        fun withdrawRewardedTokens(amount: UFix64){ 
            let vault <- self.staker.withdrawRewardedTokens(amount: amount)
            self.vault.deposit(from: <-vault)
        }
        
        access(BloctoPassPrivateEntitlement)
        fun withdrawAllUnlockedTokens(): @{FungibleToken.Vault}{ 
            let unlockedAmount = self.getTotalBalance() - self.getLockupAmount()
            let withdrawAmount = unlockedAmount < self.getIdleBalance() ? unlockedAmount : self.getIdleBalance()
            return <-self.vault.withdraw(amount: withdrawAmount)
        }
        
        access(BloctoPassPrivateEntitlement)
        fun stampBloctoPass(from: @BloctoPassStamp.NFT){ 
            self.stamps.append(from.getMessage())
            destroy from
        }
        
        access(all)
        fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
            return <-create Collection()
        }
        
        access(all)
        view fun isAvailableToWithdraw(amount: UFix64): Bool{ 
            return false
        }

        access(all) view fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>()
            ]
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: "Blocto Pass",
                        description: "",
                        thumbnail: MetadataViews.HTTPFile(
                            url: "https://raw.githubusercontent.com/portto/assets-v2/master/nft/blocto-pass/logo.png"
                        )
                    )
            }
            return nil
        }

        access(all)
        fun createEmptyVault(): Never? {
            return nil
        }
    

    }
    
    // CollectionPublic is a custom interface that allows us to
    // access the public fields and methods for our BloctoPass Collection
    access(all)
    resource interface CollectionPublic{ 
        access(all)
        fun borrowBloctoPassPublic(id: UInt64): &BloctoPass.NFT
    }
    
    access(all)
    resource interface CollectionPrivate{ 
        access(CollectionPrivateEntitlement)
        fun borrowBloctoPassPrivate(id: UInt64): auth(BloctoPass.BloctoPassPrivateEntitlement) &BloctoPass.NFT
    }
    
    access(all)
    resource Collection:  NonFungibleToken.Collection, CollectionPublic, CollectionPrivate{ 
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        access(all)
        var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
        
        init(){ 
            self.ownedNFTs <-{} 
        }
        
        // withdraw removes an NFT from the collection and moves it to the caller
        // withdrawal is disabled during lockup period
        access(NonFungibleToken.Withdraw)
        fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <-token
        }
        
        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        access(all)
        fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
            let token <- token as! @BloctoPass.NFT
            let id: UInt64 = token.id
            
            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token
            emit Deposit(id: id, to: self.owner?.address)
            destroy oldToken
        }
        
        // getIDs returns an array of the IDs that are in the collection
        access(all)
        view fun getIDs(): [UInt64]{ 
            return self.ownedNFTs.keys
        }
        
        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        access(all)
        view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
            return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
        }
        
        // borrowBloctoPassPublic gets the public references to a BloctoPass NFT in the collection
        // and returns it to the caller as a reference to the NFT
        access(all)
        fun borrowBloctoPassPublic(id: UInt64): &BloctoPass.NFT{ 
            let bloctoPassRef = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
            let intermediateRef = bloctoPassRef as! &BloctoPass.NFT
            return intermediateRef as &BloctoPass.NFT
        }
        
        // borrowBloctoPassPrivate gets the private references to a BloctoPass NFT in the collection
        // and returns it to the caller as a reference to the NFT
        access(CollectionPrivateEntitlement)
        fun borrowBloctoPassPrivate(id: UInt64): auth(BloctoPassPrivateEntitlement) &BloctoPass.NFT{ 
            let bloctoPassRef = (&self.ownedNFTs[id] as auth(BloctoPassPrivateEntitlement) &{NonFungibleToken.NFT}?)!
            return bloctoPassRef as! auth(BloctoPassPrivateEntitlement) &BloctoPass.NFT
        }
        
        access(all)
        view fun getSupportedNFTTypes():{ Type: Bool}{ 
            panic("implement me")
        }
        
        access(all)
        view fun isSupportedNFTType(type: Type): Bool{ 
            panic("implement me")
        }
        
        access(all)
        fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
            return <-create Collection()
        }
    }
    
    // public function that anyone can call to create a new empty collection
    access(all)
    fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
        return <-create Collection()
    }
    
    access(all)
    resource interface MinterPublic{ 
        access(all)
        fun mintBasicNFT(recipient: &{NonFungibleToken.CollectionPublic}): Void
    }
    
    // Resource that an admin or something similar would own to be
    // able to mint new NFTs
    //
    access(all)
    resource NFTMinter: MinterPublic{ 
        
        // adds a new predefined lockup schedule
        access(NFTMinterEntitlement)
        fun setupPredefinedLockupSchedule(lockupSchedule:{ UFix64: UFix64}){ 
            BloctoPass.predefinedLockupSchedules.append(lockupSchedule)
            emit LockupScheduleDefined(id: BloctoPass.predefinedLockupSchedules.length, lockupSchedule: lockupSchedule)
        }
        
        // updates a predefined lockup schedule
        // note that this function should be avoided 
        access(NFTMinterEntitlement)
        fun updatePredefinedLockupSchedule(id: Int, lockupSchedule:{ UFix64: UFix64}){ 
            BloctoPass.predefinedLockupSchedules[id] = lockupSchedule
            emit LockupScheduleUpdated(id: id, lockupSchedule: lockupSchedule)
        }
        
        // mintBasicNFT mints a new NFT without any special metadata or lockups
        access(all)
        fun mintBasicNFT(recipient: &{NonFungibleToken.CollectionPublic}){ 
            self.mintNFT(recipient: recipient, metadata:{} )
        }
        
        // mintNFT mints a new NFT with a new ID
        // and deposit it in the recipients collection using their collection reference
        access(NFTMinterEntitlement)
        fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String}){ 
            self.mintNFTWithCustomLockup(recipient: recipient, metadata: metadata, vault: <-BloctoToken.createEmptyVault(vaultType: Type<@BloctoToken.Vault>()), lockupSchedule:{ 0.0: 0.0})
        }
        
        access(NFTMinterEntitlement)
        fun mintNFTWithPredefinedLockup(recipient: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String}, vault: @{FungibleToken.Vault}, lockupScheduleId: Int?){ 
            
            // create a new NFT
            var newNFT <- create NFT(initID: BloctoPass.totalSupply, originalOwner: recipient.owner?.address, metadata: metadata, vault: <-vault, lockupScheduleId: lockupScheduleId, lockupSchedule: nil)
            
            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-newNFT)
            BloctoPass.totalSupply = BloctoPass.totalSupply + UInt64(1)
        }
        
        access(NFTMinterEntitlement)
        fun mintNFTWithCustomLockup(recipient: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String}, vault: @{FungibleToken.Vault}, lockupSchedule:{ UFix64: UFix64}){ 
            
            // create a new NFT
            var newNFT <- create NFT(initID: BloctoPass.totalSupply, originalOwner: recipient.owner?.address, metadata: metadata, vault: <-vault, lockupScheduleId: nil, lockupSchedule: lockupSchedule)
            
            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-newNFT)
            BloctoPass.totalSupply = BloctoPass.totalSupply + UInt64(1)
        }
    }
    
    access(all)
    fun getPredefinedLockupSchedule(id: Int):{ UFix64: UFix64}{ 
        return self.predefinedLockupSchedules[id]
    }
    
    init(){ 
        
        // Initialize the total supply
        self.totalSupply = 0
        self.predefinedLockupSchedules = []
        self.CollectionStoragePath = /storage/bloctoPassCollection
        self.CollectionPublicPath = /public/bloctoPassCollection
        self.MinterStoragePath = /storage/bloctoPassMinter
        self.MinterPublicPath = /public/bloctoPassMinter

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.storage.save(<-collection, to: self.CollectionStoragePath)
        
        // create a public capability for the collection
        var capability_1 = self.account.capabilities.storage.issue<&{NonFungibleToken.CollectionPublic, BloctoPass.CollectionPublic}>(self.CollectionStoragePath)
        self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
        
        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.storage.save(<-minter, to: self.MinterStoragePath)
        emit ContractInitialized()
    }

    /// Function that returns all the Metadata Views implemented by a Non Fungible Token
    ///
    /// @return An array of Types defining the implemented views. This value will be used by
    ///         developers to know which parameter to pass to the resolveView() method.
    ///
    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [
            Type<MetadataViews.NFTCollectionData>(),
            Type<MetadataViews.NFTCollectionDisplay>()
        ]
    }


    /// Function that resolves a metadata view for this contract.
    ///
    /// @param view: The Type of the desired view.
    /// @return A structure representing the requested view.
    ///
    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        switch viewType {
            case Type<MetadataViews.NFTCollectionData>():
                let collectionData = MetadataViews.NFTCollectionData(
                    storagePath: self.CollectionStoragePath,
                    publicPath: self.CollectionPublicPath,
                    publicCollection: Type<&BloctoPass.Collection>(),
                    publicLinkedType: Type<&BloctoPass.Collection>(),
                    createEmptyCollectionFunction: (fun(): @{NonFungibleToken.Collection} {
                        return <-BloctoPassStamp.createEmptyCollection(nftType: Type<@BloctoPass.NFT>())
                    })
                )
                return collectionData
            case Type<MetadataViews.NFTCollectionDisplay>():
                let squareImage = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(
                        url: "https://raw.githubusercontent.com/portto/assets-v2/master/nft/blocto-pass/logo.png"
                    ),
                    mediaType: "image/png"
                )
                let bannerImage = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(
                        url: "https://raw.githubusercontent.com/portto/assets-v2/master/nft/blocto-pass/banner.png"
                    ),
                    mediaType: "image/png"
                )
                return MetadataViews.NFTCollectionDisplay(
                    name: "Blcoto Pass Stamp",
                    description: "",
                    externalURL: MetadataViews.ExternalURL("https://blocto.io/"),
                    squareImage: squareImage,
                    bannerImage: bannerImage,
                    socials: {
                        "twitter": MetadataViews.ExternalURL("https://x.com/BloctoApp")
                    }
                )
        }
        return nil
    } 
}