/*

    BloctoTokenStaking

    The BloctoToken Staking contract manages
    node operators' and delegators' information
    and Flow tokens that are staked as part of the Flow Protocol.

 */

import FungibleToken from "../token/FungibleToken.cdc"
import BloctoToken from "../token/BloctoToken.cdc"

pub contract BloctoTokenStaking {

    /****** ID Table and Staking Events ******/

    pub event NewEpoch(totalStaked: UFix64, totalRewardPayout: UFix64)

    /// Staker Events
    pub event NewStakerCreated(stakerID: UInt64, amountCommitted: UFix64)
    pub event TokensCommitted(stakerID: UInt64, amount: UFix64)
    pub event TokensStaked(stakerID: UInt64, amount: UFix64)
    pub event TokensUnstaking(stakerID: UInt64, amount: UFix64)
    pub event TokensUnstaked(stakerID: UInt64, amount: UFix64)
    pub event NodeRemovedAndRefunded(stakerID: UInt64, amount: UFix64)
    pub event RewardsPaid(stakerID: UInt64, amount: UFix64)
    pub event UnstakedTokensWithdrawn(stakerID: UInt64, amount: UFix64)
    pub event RewardTokensWithdrawn(stakerID: UInt64, amount: UFix64)

    /// Contract Field Change Events
    pub event NewWeeklyPayout(newPayout: UFix64)

    /// Holds the identity table for all the nodes in the network.
    /// Includes nodes that aren't actively participating
    /// key = node ID
    /// value = the record of that node's info, tokens, and delegators
    access(contract) var stakers: @{UInt64: StakerRecord}

    /// The total amount of tokens that are staked for all the nodes
    /// of each node type during the current epoch
    access(contract) var totalTokensStaked: UFix64

    /// The total amount of tokens that are paid as rewards every epoch
    /// could be manually changed by the admin resource
    access(contract) var epochTokenPayout: UFix64

    /// Paths for storing staking resources
    pub let StakerStoragePath: StoragePath
    pub let StakerPublicPath: PublicPath
    pub let StakingAdminStoragePath: StoragePath

    /*********** ID Table and Staking Composite Type Definitions *************/

    /// Contains information that is specific to a node in Flow
    pub resource StakerRecord {

        /// The unique ID of the staker
        /// Corresponds to the BloctoPass NFT ID
        pub let id: UInt64

        /// The total tokens that only this node currently has staked, not including delegators
        /// This value must always be above the minimum requirement to stay staked or accept delegators
        pub var tokensStaked: @BloctoToken.Vault

        /// The tokens that this node has committed to stake for the next epoch.
        pub var tokensCommitted: @BloctoToken.Vault

        /// The tokens that this node has unstaked from the previous epoch
        /// Moves to the tokensUnstaked bucket at the end of the epoch.
        pub var tokensUnstaking: @BloctoToken.Vault

        /// Tokens that this node is able to withdraw whenever they want
        pub var tokensUnstaked: @BloctoToken.Vault

        /// Staking rewards are paid to this bucket
        /// Can be withdrawn whenever
        pub var tokensRewarded: @BloctoToken.Vault

        /// The amount of tokens that this node has requested to unstake for the next epoch
        pub(set) var tokensRequestedToUnstake: UFix64

        init(
            id: UInt64,
            tokensCommitted: @FungibleToken.Vault
        ) {
            pre {
                BloctoTokenStaking.stakers[id] == nil: "The ID cannot already exist in the record"
            }

            self.id = id

            self.tokensCommitted <- tokensCommitted as! @BloctoToken.Vault
            self.tokensStaked <- BloctoToken.createEmptyVault() as! @BloctoToken.Vault
            self.tokensUnstaking <- BloctoToken.createEmptyVault() as! @BloctoToken.Vault
            self.tokensUnstaked <- BloctoToken.createEmptyVault() as! @BloctoToken.Vault
            self.tokensRewarded <- BloctoToken.createEmptyVault() as! @BloctoToken.Vault
            self.tokensRequestedToUnstake = 0.0

            emit NewStakerCreated(stakerID: self.id, amountCommitted: self.tokensCommitted.balance)
        }

        destroy() {
            let BloctoTokenRef = BloctoTokenStaking.account.borrow<&BloctoToken.Vault>(from: /storage/BloctoTokenVault)!
            BloctoTokenStaking.totalTokensStaked = BloctoTokenStaking.totalTokensStaked - self.tokensStaked.balance
            BloctoTokenRef.deposit(from: <-self.tokensStaked)
            BloctoTokenRef.deposit(from: <-self.tokensCommitted)
            BloctoTokenRef.deposit(from: <-self.tokensUnstaking)
            BloctoTokenRef.deposit(from: <-self.tokensUnstaked)
            BloctoTokenRef.deposit(from: <-self.tokensRewarded)
        }

        /// Utility Function that checks a node's overall committed balance from its borrowed record
        access(contract) fun nodeFullCommittedBalance(): UFix64 {
            if (self.tokensCommitted.balance + self.tokensStaked.balance) < self.tokensRequestedToUnstake {
                return 0.0
            } else {
                return self.tokensCommitted.balance + self.tokensStaked.balance - self.tokensRequestedToUnstake
            }
        }
    }

    /// Struct to create to get read-only info about a node
    pub struct StakerInfo {
        pub let id: UInt64
        pub let tokensStaked: UFix64
        pub let tokensCommitted: UFix64
        pub let tokensUnstaking: UFix64
        pub let tokensUnstaked: UFix64
        pub let tokensRewarded: UFix64
        pub let tokensRequestedToUnstake: UFix64

        init(stakerID: UInt64) {
            let stakerRecord = BloctoTokenStaking.borrowStakerRecord(stakerID)

            self.id = stakerRecord.id
            self.tokensStaked = stakerRecord.tokensStaked.balance
            self.tokensCommitted = stakerRecord.tokensCommitted.balance
            self.tokensUnstaking = stakerRecord.tokensUnstaking.balance
            self.tokensUnstaked = stakerRecord.tokensUnstaked.balance
            self.tokensRewarded = stakerRecord.tokensRewarded.balance
            self.tokensRequestedToUnstake = stakerRecord.tokensRequestedToUnstake
        }

        /// Derived Fields
        pub fun totalCommittedWithDelegators(): UFix64 {
            let stakerRecord = BloctoTokenStaking.borrowStakerRecord(self.id)
            var committedSum = self.totalCommittedWithoutDelegators()
            return committedSum
        }

        pub fun totalCommittedWithoutDelegators(): UFix64 {
            let stakerRecord = BloctoTokenStaking.borrowStakerRecord(self.id)
            return stakerRecord.nodeFullCommittedBalance()
        }

        pub fun totalTokensInRecord(): UFix64 {
            return self.tokensStaked + self.tokensCommitted + self.tokensUnstaking + self.tokensUnstaked + self.tokensRewarded
        }
    }

    /// Records the staking info associated with a delegator
    /// This resource is stored in the StakerRecord object that is being delegated to
    pub resource DelegatorRecord {
        /// Tokens this delegator has committed for the next epoch
        pub var tokensCommitted: @BloctoToken.Vault

        /// Tokens this delegator has staked for the current epoch
        pub var tokensStaked: @BloctoToken.Vault

        /// Tokens this delegator has requested to unstake and is locked for the current epoch
        pub var tokensUnstaking: @BloctoToken.Vault

        /// Tokens this delegator has been rewarded and can withdraw
        pub let tokensRewarded: @BloctoToken.Vault

        /// Tokens that this delegator unstaked and can withdraw
        pub let tokensUnstaked: @BloctoToken.Vault

        /// Amount of tokens that the delegator has requested to unstake
        pub(set) var tokensRequestedToUnstake: UFix64

        init() {
            self.tokensCommitted <- BloctoToken.createEmptyVault() as! @BloctoToken.Vault
            self.tokensStaked <- BloctoToken.createEmptyVault() as! @BloctoToken.Vault
            self.tokensUnstaking <- BloctoToken.createEmptyVault() as! @BloctoToken.Vault
            self.tokensRewarded <- BloctoToken.createEmptyVault() as! @BloctoToken.Vault
            self.tokensUnstaked <- BloctoToken.createEmptyVault() as! @BloctoToken.Vault
            self.tokensRequestedToUnstake = 0.0
        }

        destroy () {
            destroy self.tokensCommitted
            destroy self.tokensStaked
            destroy self.tokensUnstaking
            destroy self.tokensRewarded
            destroy self.tokensUnstaked
        }

        /// Utility Function that checks a delegator's overall committed balance from its borrowed record
        access(contract) fun delegatorFullCommittedBalance(): UFix64 {
            if (self.tokensCommitted.balance + self.tokensStaked.balance) < self.tokensRequestedToUnstake {
                return 0.0
            } else {
                return self.tokensCommitted.balance + self.tokensStaked.balance - self.tokensRequestedToUnstake
            }
        }
    }

    pub resource interface StakerPublic {
        pub let id: UInt64
    }

    /// Resource that the node operator controls for staking
    pub resource Staker: StakerPublic {

        /// Unique ID for the node operator
        pub let id: UInt64

        init(id: UInt64) {
            self.id = id
        }

        /// Add new tokens to the system to stake during the next epoch
        pub fun stakeNewTokens(_ tokens: @FungibleToken.Vault) {
            pre {
                BloctoTokenStaking.stakingEnabled(): "Cannot stake if the staking auction isn't in progress"
            }

            // Borrow the node's record from the staking contract
            let stakerRecord = BloctoTokenStaking.borrowStakerRecord(self.id)

            emit TokensCommitted(stakerID: stakerRecord.id, amount: tokens.balance)

            // Add the new tokens to tokens committed
            stakerRecord.tokensCommitted.deposit(from: <-tokens)
        }

        /// Stake tokens that are in the tokensUnstaked bucket
        pub fun stakeUnstakedTokens(amount: UFix64) {
            pre {
                BloctoTokenStaking.stakingEnabled(): "Cannot stake if the staking auction isn't in progress"
            }

            let stakerRecord = BloctoTokenStaking.borrowStakerRecord(self.id)

            var remainingAmount = amount

            // If there are any tokens that have been requested to unstake for the current epoch,
            // cancel those first before staking new unstaked tokens
            if remainingAmount <= stakerRecord.tokensRequestedToUnstake {
                stakerRecord.tokensRequestedToUnstake = stakerRecord.tokensRequestedToUnstake - remainingAmount
                remainingAmount = 0.0
            } else if remainingAmount > stakerRecord.tokensRequestedToUnstake {
                remainingAmount = remainingAmount - stakerRecord.tokensRequestedToUnstake
                stakerRecord.tokensRequestedToUnstake = 0.0
            }

            // Commit the remaining amount from the tokens unstaked bucket
            stakerRecord.tokensCommitted.deposit(from: <-stakerRecord.tokensUnstaked.withdraw(amount: remainingAmount))

            emit TokensCommitted(stakerID: stakerRecord.id, amount: remainingAmount)
        }

        /// Stake tokens that are in the tokensRewarded bucket
        pub fun stakeRewardedTokens(amount: UFix64) {
            pre {
                BloctoTokenStaking.stakingEnabled(): "Cannot stake if the staking auction isn't in progress"
            }

            let stakerRecord = BloctoTokenStaking.borrowStakerRecord(self.id)

            stakerRecord.tokensCommitted.deposit(from: <-stakerRecord.tokensRewarded.withdraw(amount: amount))

            emit TokensCommitted(stakerID: stakerRecord.id, amount: amount)
        }

        /// Request amount tokens to be removed from staking at the end of the next epoch
        pub fun requestUnstaking(amount: UFix64) {
            pre {
                BloctoTokenStaking.stakingEnabled(): "Cannot unstake if the staking auction isn't in progress"
            }

            let stakerRecord = BloctoTokenStaking.borrowStakerRecord(self.id)

            // If the request is greater than the total number of tokens
            // that can be unstaked, revert
            assert (
                stakerRecord.tokensStaked.balance +
                stakerRecord.tokensCommitted.balance
                >= amount + stakerRecord.tokensRequestedToUnstake,
                message: "Not enough tokens to unstake!"
            )

            // Get the balance of the tokens that are currently committed
            let amountCommitted = stakerRecord.tokensCommitted.balance

            // If the request can come from committed, withdraw from committed to unstaked
            if amountCommitted >= amount {

                // withdraw the requested tokens from committed since they have not been staked yet
                stakerRecord.tokensUnstaked.deposit(from: <-stakerRecord.tokensCommitted.withdraw(amount: amount))

            } else {
                let amountCommitted = stakerRecord.tokensCommitted.balance

                // withdraw the requested tokens from committed since they have not been staked yet
                stakerRecord.tokensUnstaked.deposit(from: <-stakerRecord.tokensCommitted.withdraw(amount: amountCommitted))

                // update request to show that leftover amount is requested to be unstaked
                stakerRecord.tokensRequestedToUnstake = stakerRecord.tokensRequestedToUnstake + (amount - amountCommitted)
            }
        }

        /// Requests to unstake all of the node operators staked and committed tokens
        /// as well as all the staked and committed tokens of all of their delegators
        pub fun unstakeAll() {
            pre {
                BloctoTokenStaking.stakingEnabled(): "Cannot unstake if the staking auction isn't in progress"
            }

            let stakerRecord = BloctoTokenStaking.borrowStakerRecord(self.id)

            /// if the request can come from committed, withdraw from committed to unstaked
            /// withdraw the requested tokens from committed since they have not been staked yet
            stakerRecord.tokensUnstaked.deposit(from: <-stakerRecord.tokensCommitted.withdraw(amount: stakerRecord.tokensCommitted.balance))

            /// update request to show that leftover amount is requested to be unstaked
            stakerRecord.tokensRequestedToUnstake = stakerRecord.tokensStaked.balance
        }

        /// Withdraw tokens from the unstaked bucket
        pub fun withdrawUnstakedTokens(amount: UFix64): @FungibleToken.Vault {

            let stakerRecord = BloctoTokenStaking.borrowStakerRecord(self.id)

            emit UnstakedTokensWithdrawn(stakerID: stakerRecord.id, amount: amount)

            return <- stakerRecord.tokensUnstaked.withdraw(amount: amount)
        }

        /// Withdraw tokens from the rewarded bucket
        pub fun withdrawRewardedTokens(amount: UFix64): @FungibleToken.Vault {

            let stakerRecord = BloctoTokenStaking.borrowStakerRecord(self.id)

            emit RewardTokensWithdrawn(stakerID: stakerRecord.id, amount: amount)

            return <- stakerRecord.tokensRewarded.withdraw(amount: amount)
        }
    }

    /// Admin resource that has the ability to create new staker objects, remove insufficiently staked nodes
    /// at the end of the staking auction, and pay rewards to nodes at the end of an epoch
    pub resource Admin {

        /// Remove a node from the record
        pub fun removeNode(_ stakerID: UInt64): @StakerRecord {
            let staker <- BloctoTokenStaking.stakers.remove(key: stakerID)
                ?? panic("Could not find a node with the specified ID")

            return <-staker
        }

        /// Starts the staking auction, the period when nodes and delegators
        /// are allowed to perform staking related operations
        pub fun startStakingAuction() {
            BloctoTokenStaking.account.load<Bool>(from: /storage/stakingEnabled)
            BloctoTokenStaking.account.save(true, to: /storage/stakingEnabled)
        }

        /// Ends the staking Auction by removing any unapproved nodes
        /// and setting stakingEnabled to false
        pub fun endStakingAuction() {
            BloctoTokenStaking.account.load<Bool>(from: /storage/stakingEnabled)
            BloctoTokenStaking.account.save(false, to: /storage/stakingEnabled)
        }

        /// Called at the end of the epoch to pay rewards to node operators
        /// based on the tokens that they have staked
        pub fun payRewards() {

            let allstakerIDs = BloctoTokenStaking.getstakerIDs()

            let BloctoTokenMinter = BloctoTokenStaking.account.borrow<&BloctoToken.Minter>(from: /storage/BloctoTokenMinter)
                ?? panic("Could not borrow minter reference")

            // calculate the total number of tokens staked
            var totalStaked = BloctoTokenStaking.getTotalStaked()

            if totalStaked == 0.0 {
                return
            }
            var totalRewardScale = BloctoTokenStaking.epochTokenPayout / totalStaked

            /// iterate through all the nodes to pay
            for stakerID in allstakerIDs {
                let stakerRecord = BloctoTokenStaking.borrowStakerRecord(stakerID)

                if stakerRecord.tokensStaked.balance == 0.0 { continue }

                let rewardAmount = stakerRecord.tokensStaked.balance * totalRewardScale

                if rewardAmount == 0.0 { continue }

                /// Mint the tokens to reward the operator
                let tokenReward <- BloctoTokenMinter.mintTokens(amount: rewardAmount)

                if tokenReward.balance > 0.0 {
                    emit RewardsPaid(stakerID: stakerRecord.id, amount: tokenReward.balance)

                    /// Deposit the node Rewards into their tokensRewarded bucket
                    stakerRecord.tokensRewarded.deposit(from: <-tokenReward)
                } else {
                    destroy tokenReward
                }
            }
        }

        /// Called at the end of the epoch to move tokens between buckets
        /// for stakers
        /// Tokens that have been committed are moved to the staked bucket
        /// Tokens that were unstaking during the last epoch are fully unstaked
        /// Unstaking requests are filled by moving those tokens from staked to unstaking
        pub fun moveTokens() {
            pre {
                !BloctoTokenStaking.stakingEnabled(): "Cannot move tokens if the staking auction is still in progress"
            }
            
            let allstakerIDs = BloctoTokenStaking.getstakerIDs()

            for stakerID in allstakerIDs {
                let stakerRecord = BloctoTokenStaking.borrowStakerRecord(stakerID)

                // Update total number of tokens staked by all the nodes of each type
                BloctoTokenStaking.totalTokensStaked = BloctoTokenStaking.totalTokensStaked + stakerRecord.tokensCommitted.balance

                // mark the committed tokens as staked
                if stakerRecord.tokensCommitted.balance > 0.0 {
                    emit TokensStaked(stakerID: stakerRecord.id, amount: stakerRecord.tokensCommitted.balance)
                    stakerRecord.tokensStaked.deposit(from: <-stakerRecord.tokensCommitted.withdraw(amount: stakerRecord.tokensCommitted.balance))
                }

                // marked the unstaking tokens as unstaked
                if stakerRecord.tokensUnstaking.balance > 0.0 {
                    emit TokensUnstaked(stakerID: stakerRecord.id, amount: stakerRecord.tokensUnstaking.balance)
                    stakerRecord.tokensUnstaked.deposit(from: <-stakerRecord.tokensUnstaking.withdraw(amount: stakerRecord.tokensUnstaking.balance))
                }

                // unstake the requested tokens and move them to tokensUnstaking
                if stakerRecord.tokensRequestedToUnstake > 0.0 {
                    emit TokensUnstaking(stakerID: stakerRecord.id, amount: stakerRecord.tokensRequestedToUnstake)
                    stakerRecord.tokensUnstaking.deposit(from: <-stakerRecord.tokensStaked.withdraw(amount: stakerRecord.tokensRequestedToUnstake))
                }

                // subtract their requested tokens from the total staked for their node type
                BloctoTokenStaking.totalTokensStaked = BloctoTokenStaking.totalTokensStaked - stakerRecord.tokensRequestedToUnstake

                // Reset the tokens requested field so it can be used for the next epoch
                stakerRecord.tokensRequestedToUnstake = 0.0
            }

            // Start the new epoch's staking auction
            self.startStakingAuction()

            emit NewEpoch(totalStaked: BloctoTokenStaking.getTotalStaked(), totalRewardPayout: BloctoTokenStaking.epochTokenPayout)
        }

        /// Changes the total weekly payout to a new value
        pub fun setEpochTokenPayout(_ newPayout: UFix64) {
            BloctoTokenStaking.epochTokenPayout = newPayout

            emit NewWeeklyPayout(newPayout: newPayout)
        }
    }

    /// Any node can call this function to register a new Node
    /// It returns the resource for nodes that they can store in their account storage
    pub fun addStakerRecord(id: UInt64, tokensCommitted: @FungibleToken.Vault): @Staker {
        pre {
            BloctoTokenStaking.stakingEnabled(): "Cannot register a node operator if the staking auction isn't in progress"
        }

        let newStakerRecord <- create StakerRecord(id: id, tokensCommitted: <-tokensCommitted)

        // Insert the node to the table
        BloctoTokenStaking.stakers[id] <-! newStakerRecord

        // return a new Staker object that the node operator stores in their account
        return <-create Staker(id: id)
    }

    /// borrow a reference to to one of the nodes in the record
    access(account) fun borrowStakerRecord(_ stakerID: UInt64): &StakerRecord {
        pre {
            BloctoTokenStaking.stakers[stakerID] != nil:
                "Specified node ID does not exist in the record"
        }
        return &BloctoTokenStaking.stakers[stakerID] as! &StakerRecord
    }

    /// Updates a claimed boolean for a specific path to indicate that
    /// a piece of node metadata has been claimed by a node
    access(account) fun updateClaimed(path: StoragePath, _ key: String, claimed: Bool) {
        let claimedDictionary = self.account.load<{String: Bool}>(from: path)
            ?? panic("Invalid path for dictionary")

        if claimed {
            claimedDictionary[key] = true
        } else {
            claimedDictionary[key] = nil
        }

        self.account.save(claimedDictionary, to: path)
    }

    /// Indicates if the staking auction is currently enabled
    pub fun stakingEnabled(): Bool {
        return self.account.copy<Bool>(from: /storage/stakingEnabled) ?? false
    }

    /// Gets an array of all the stakerIDs that are staked.
    /// Only nodes that are participating in the current epoch
    /// can be staked, so this is an array of all the active
    /// node operators
    pub fun getStakedstakerIDs(): [UInt64] {
        var stakedNodes: [UInt64] = []

        for stakerID in BloctoTokenStaking.getstakerIDs() {
            let stakerRecord = BloctoTokenStaking.borrowStakerRecord(stakerID)

            // To be considered staked, a node has to have tokens staked equal or above the minimum
            // Access nodes have a minimum of 0, so they need to be strictly greater than zero to be considered staked
            if stakerRecord.tokensStaked.balance > 0.0
            {
                stakedNodes.append(stakerID)
            }
        }

        return stakedNodes
    }

    /// Gets an array of all the node IDs that have ever registered
    pub fun getstakerIDs(): [UInt64] {
        return BloctoTokenStaking.stakers.keys
    }

    /// Gets the total number of FLOW that is currently staked
    /// by all of the staked nodes in the current epoch
    pub fun getTotalStaked(): UFix64 {
        return BloctoTokenStaking.totalTokensStaked
    }

    init(_ epochTokenPayout: UFix64, _ rewardCut: UFix64) {
        self.account.save(true, to: /storage/stakingEnabled)

        self.stakers <- {}

        self.StakerStoragePath = /storage/flowStaker
        self.StakerPublicPath = /public/flowStaker
        self.StakingAdminStoragePath = /storage/flowStakingAdmin

        self.totalTokensStaked = 0.0

        self.epochTokenPayout = epochTokenPayout

        self.account.save(<-create Admin(), to: self.StakingAdminStoragePath)
    }
}
 