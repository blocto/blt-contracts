import FungibleToken from "../token/FungibleToken.cdc"
import NonFungibleToken from "../token/NonFungibleToken.cdc"
import BloctoToken from "../token/BloctoToken.cdc"
import BloctoPass from "../token/BloctoPass.cdc"

pub contract BloctoTokenMining {

    // Event that is emitted when mining state is updated
    pub event MiningStateUpdated(state: UInt8)

    // Event that is emitted when go to next round
    pub event RoundUpdated(round: UInt64)

    // Event that is emitted when reward cap is updated
    pub event RewardCapUpdated(rewardCap: UFix64)

    // Event that is emitted when cap multiplier is updated
    pub event CapMultiplierUpdated(capMultiplier: UInt64)

    // Event that is emitted when new criteria is updated
    pub event CriteriaUpdated(name: String, criterion: Criterion?)

    // Event that is emitted when reward lock period is updated
    pub event RewardLockPeriodUpdated(rewardLockPeriod: UInt64)

    // Event that is emitted when reward lock ratio is updated
    pub event RewardLockRatioUpdated(rewardLockRatio: UFix64)

    // Event that is emitted when mining raw data is collected
    pub event DataCollected(data: {String: UFix64}, address: Address, reward: UFix64, replacedReward: UFix64?)

    // Event that is emitted when reward is distributed
    pub event RewardDistributed(reward: UFix64, address: Address)

    // Event that is emiited when reward is withdrawn
    pub event RewardWithdrawn(amount: UFix64, from: Address?)

    // Criterion
    //
    // Define mining criterion
    //
    pub struct Criterion {

        // The reward a user can mine if achieving the goal
        pub var reward: UFix64

        // Divisor to adjust raw data
        pub var divisor: UFix64

        // Cap times in one round
        pub var capTimes: UInt64

        init(reward: UFix64, divisor: UFix64, capTimes: UInt64) {
            self.reward = reward
            self.divisor = divisor
            self.capTimes = capTimes
        }
    }

    pub struct RewardLockInfo {
        pub let fromRound: UInt64
        pub let lockRound: UInt64
        pub let amount: UFix64

        init(fromRound: UInt64, lockRound: UInt64, amount: UFix64) {
            self.fromRound = fromRound
            self.lockRound = lockRound
            self.amount = amount
        }
    }

    // MiningState
    //
    // Define mining state
    //
    pub enum MiningState: UInt8 {
        pub case initial
        pub case collecting
        pub case collected
        pub case distributed
    }

    // Defines mining reward storage path
    pub let MiningRewardStoragePath: StoragePath

    // Defines mining reward public balance path
    pub let MiningRewardPublicPath: PublicPath

    // Defines mining admin storage path
    pub let MiningAdminStoragePath: StoragePath

    // Define mining state
    access(contract) var miningState: MiningState

    // Define current round
    access(contract) var currentRound: UInt64

    // Define current total reward computed by users' raw data
    access(contract) var currentTotalReward: UFix64

    // Define reward cap
    access(contract) var rewardCap: UFix64

    // Define cap multipier for VIP-tier users
    access(contract) var capMultiplier: UInt64

    // Define mining criteria
    // criteria name => Criteria
    access(contract) var criteria: {String: Criterion}

    // Define reward lock period
    access(contract) var rewardLockPeriod: UInt64

    // Define reward lock ratio
    access(contract) var rewardLockRatio: UFix64

    // Define if user reward is collected
    // Address => round
    access(contract) var userRewardsCollected: {Address: UInt64}

    // Define user rewards in current round
    // This doesn't consider reward cap
    access(contract) var userRewards: {Address: UFix64}

    // Define if reward is distributed
    // Address => round
    access(contract) var rewardsDistributed: {Address: UInt64}

    // Administrator
    //
    pub resource Administrator {

        // Start collecting users' raw data
        pub fun startCollecting() {
            BloctoTokenMining.miningState = MiningState.collecting

            emit MiningStateUpdated(state: BloctoTokenMining.miningState.rawValue)
        }

        // Stop collecting users' raw data
        pub fun stopCollecting() {
            BloctoTokenMining.miningState = MiningState.collected

            emit MiningStateUpdated(state: BloctoTokenMining.miningState.rawValue)
        }

        // Finish distributing reward 
        pub fun finishDistributing() {
            BloctoTokenMining.miningState = MiningState.distributed

            emit MiningStateUpdated(state: BloctoTokenMining.miningState.rawValue)
        }

        // Go to next round and reset total reward
        pub fun goNextRound() {
            pre {
                BloctoTokenMining.miningState == MiningState.initial ||
                    BloctoTokenMining.miningState == MiningState.distributed:
                    "Current round should be distributed"
            }
            BloctoTokenMining.currentRound = BloctoTokenMining.currentRound + (1 as UInt64)
            BloctoTokenMining.currentTotalReward = 0.0

            emit RoundUpdated(round: BloctoTokenMining.currentRound)

            self.startCollecting()
        }

        // Update reward cap
        pub fun updateRewardCap(_ rewardCap: UFix64) {
            BloctoTokenMining.rewardCap = rewardCap

            emit RewardCapUpdated(rewardCap: rewardCap)
        }

        // Update cap multiplier
        pub fun updateCapMultiplier(_ capMultiplier: UInt64) {
            pre {
                BloctoTokenMining.miningState == MiningState.initial ||
                    BloctoTokenMining.miningState == MiningState.collected:
                    "Current round should be collected"
            }
            BloctoTokenMining.capMultiplier = capMultiplier

            emit CapMultiplierUpdated(capMultiplier: capMultiplier)
        }

        // Update criterion by name
        pub fun updateCriterion(name: String, criterion: Criterion?) {
            pre {
                BloctoTokenMining.miningState == MiningState.initial ||
                    BloctoTokenMining.miningState == MiningState.collected:
                    "Current round should be collected"
            }
            BloctoTokenMining.criteria[name] = criterion

            emit CriteriaUpdated(name: name, criterion: criterion)
        }

        pub fun updateRewardLockPeriod(_ rewardLockPeriod: UInt64) {
            pre {
                BloctoTokenMining.miningState != MiningState.collected: "Should NOT be collected"
            }
            BloctoTokenMining.rewardLockPeriod = rewardLockPeriod

            emit RewardLockPeriodUpdated(rewardLockPeriod: rewardLockPeriod)
        }

        pub fun updateRewardLockRatio(_ rewardLockRatio: UFix64) {
            pre {
                BloctoTokenMining.miningState != MiningState.collected: "Should NOT be collected"
                rewardLockRatio <= 1.0: "ratio should be less than or equal to 1"
            }
            BloctoTokenMining.rewardLockRatio = rewardLockRatio

            emit RewardLockRatioUpdated(rewardLockRatio: rewardLockRatio)
        }

        // Collect raw data
        // data: {criteria name: raw data}
        pub fun collectData(_ data: {String: UFix64}, address: Address) {
            pre {
                BloctoTokenMining.miningState == MiningState.collecting: "Should start collecting"
            }

            // Check if the address has MiningRewardPublicPath
            let miningRewardRef = getAccount(address).getCapability(BloctoTokenMining.MiningRewardPublicPath)
                .borrow<&{BloctoTokenMining.MiningRewardPublic}>()
                ?? panic("Could not borrow mining reward public reference")

            let isVIP = BloctoTokenMining.isAddressVIP(address: address)
            let round = BloctoTokenMining.userRewardsCollected[address] ?? (0 as UInt64)
            if round < BloctoTokenMining.currentRound {
                let reward = BloctoTokenMining.computeReward(data: data, isVIP: isVIP)

                BloctoTokenMining.currentTotalReward = BloctoTokenMining.currentTotalReward + reward
                BloctoTokenMining.userRewards[address] = reward

                emit DataCollected(data: data, address: address, reward: reward, replacedReward: nil)
            } else if round == BloctoTokenMining.currentRound {
                let replacedReward = BloctoTokenMining.userRewards[address]!
                let reward = BloctoTokenMining.computeReward(data: data, isVIP: isVIP)

                BloctoTokenMining.currentTotalReward = BloctoTokenMining.currentTotalReward - replacedReward + reward
                BloctoTokenMining.userRewards[address] = reward

                emit DataCollected(data: data, address: address, reward: reward, replacedReward: replacedReward)
            } else {
                panic("Reward collected round must less than or equal to current round")
            }

            BloctoTokenMining.userRewardsCollected[address] = BloctoTokenMining.currentRound
        }

        // Distribute reward by address
        pub fun distributeReward(address: Address) {
            pre {
                BloctoTokenMining.miningState == MiningState.collected: "Should stop collecting"
                BloctoTokenMining.rewardsDistributed[address] ?? (0 as UInt64) < BloctoTokenMining.currentRound:
                    "Same address in currrent round already distributed"
            }
            post {
                BloctoTokenMining.rewardsDistributed[address] == BloctoTokenMining.currentRound:
                    "Same address in currrent round should be distributed"
            }

            let reward = BloctoTokenMining.computeFinalReward(
                address: address,
                totalReward: BloctoTokenMining.currentTotalReward)
            let bloctoTokenMinter = BloctoTokenMining.account.borrow<&BloctoToken.Minter>(from: BloctoToken.TokenMinterStoragePath)
                ?? panic("Could not borrow minter reference")
            let rewardVault <- bloctoTokenMinter.mintTokens(amount: reward)

            let lockReward = reward * BloctoTokenMining.rewardLockRatio
            let lockRewardVault <- rewardVault.withdraw(amount: lockReward) as! @BloctoToken.Vault
            let lockRound = BloctoTokenMining.currentRound + BloctoTokenMining.rewardLockPeriod
            
            let miningRewardRef = getAccount(address).getCapability(BloctoTokenMining.MiningRewardPublicPath)
                .borrow<&{BloctoTokenMining.MiningRewardPublic}>()
                ?? panic("Could not borrow mining reward public reference")
            miningRewardRef.deposit(reward: <- rewardVault, lockRound: BloctoTokenMining.currentRound, fromRound: BloctoTokenMining.currentRound)
            miningRewardRef.deposit(reward: <- lockRewardVault, lockRound: lockRound, fromRound: BloctoTokenMining.currentRound)

            BloctoTokenMining.rewardsDistributed[address] = BloctoTokenMining.currentRound

            emit RewardDistributed(reward: reward, address: address)
        }

        access(self) fun getHighestTierBloctoPass(address: Address): &BloctoPass.NFT{NonFungibleToken.INFT}? {
            let collectionRef = getAccount(address).getCapability(BloctoPass.CollectionPublicPath)
                .borrow<&{NonFungibleToken.CollectionPublic, BloctoPass.CollectionPublic}>()
                ?? panic("Could not borrow collection public reference")

            var highestTier: UInt64? = nil
            var highestBloctoPass: &BloctoPass.NFT{NonFungibleToken.INFT}? = nil
            for id in collectionRef.getIDs() {
                let bloctoPass = collectionRef.borrowBloctoPassPublic(id: id)
                let tier = bloctoPass.getVipTier()
                if let localHighestTier = highestTier {
                    if tier > localHighestTier {
                        highestTier = tier
                        highestBloctoPass = bloctoPass
                    }
                } else {
                    highestTier = tier
                    highestBloctoPass = bloctoPass
                }
            }
            return highestBloctoPass
        }
    }

    pub resource interface MiningRewardPublic {
        pub fun getRewardsLocked(): [RewardLockInfo]
        pub fun computeUnlocked(): UFix64
        access(contract) fun deposit(reward: @BloctoToken.Vault, lockRound: UInt64, fromRound: UInt64)
    }

    pub resource MiningReward: MiningRewardPublic {

        // Define reward lock info
        access(self) var rewardsLocked: [RewardLockInfo]

        // Define reward lock vault
        access(self) let reward: @BloctoToken.Vault

        pub fun getRewardsLocked(): [RewardLockInfo] {
            return self.rewardsLocked
        }

        pub fun computeUnlocked(): UFix64 {
            var amount: UFix64 = 0.0
            for info in self.rewardsLocked {
                if info.lockRound < BloctoTokenMining.currentRound {
                    amount = amount + info.amount
                }
            }
            return amount
        }

        access(contract) fun deposit(reward: @BloctoToken.Vault, lockRound: UInt64, fromRound: UInt64) {
            let lockInfo = RewardLockInfo(fromRound: fromRound, lockRound: lockRound, amount: reward.balance)
            self.rewardsLocked.append(lockInfo)
            self.reward.deposit(from: <- reward)
        }

        pub fun withdraw(): @BloctoToken.Vault {
            var amount: UFix64 = 0.0
            var index = self.rewardsLocked.length - 1
            while index >= 0 {
                let info = self.rewardsLocked[index]
                if info.lockRound < BloctoTokenMining.currentRound {
                    amount = amount + info.amount
                    self.rewardsLocked.remove(at: index)
                }
                index = index - 1
            }
            emit RewardWithdrawn(amount: amount, from: self.owner?.address)
            return <- (self.reward.withdraw(amount: amount) as! @BloctoToken.Vault)
        }

        init() {
            self.rewardsLocked = []
            self.reward <- BloctoToken.createEmptyVault() as! @BloctoToken.Vault
        }

        destroy() {
            destroy self.reward
        }
    }

    pub fun getMiningState(): MiningState {
        return self.miningState
    }

    pub fun getCurrentRound(): UInt64 {
        return self.currentRound
    }

    pub fun getCurrentTotalReward(): UFix64 {
        return self.currentTotalReward
    }

    pub fun getRewardCap(): UFix64 {
        return self.rewardCap
    }

    pub fun getCapMultiplier(): UInt64 {
        return self.capMultiplier
    }

    pub fun getCriteria(): {String: Criterion} {
        return self.criteria
    }

    pub fun getRewardLockPeriod(): UInt64 {
        return self.rewardLockPeriod
    }

    pub fun getRewardLockRatio(): UFix64 {
        return self.rewardLockRatio
    }

    pub fun getUserRewardsCollected(): {Address: UInt64} {
        return self.userRewardsCollected
    }

    pub fun getUserRewards(): {Address: UFix64} {
        return self.userRewards
    }

    pub fun getRewardsDistributed(): {Address: UInt64} {
        return self.rewardsDistributed
    }

    // Chceck if the address is VIP
    pub fun isAddressVIP(address: Address): Bool {
        let collectionRef = getAccount(address).getCapability(BloctoPass.CollectionPublicPath)
            .borrow<&{NonFungibleToken.CollectionPublic, BloctoPass.CollectionPublic}>()
            ?? panic("Could not borrow collection public reference")

        for id in collectionRef.getIDs() {
            let bloctoPass = collectionRef.borrowBloctoPassPublic(id: id)
            if bloctoPass.getVipTier() > (0 as UInt64) {
                return true
            }
        }
        return false
    }

    // Compute reward in current round without reward cap
    pub fun computeReward(data: {String: UFix64}, isVIP: Bool): UFix64 {
        var reward: UFix64 = 0.0
        for name in data.keys {
            let value = data[name]!
            let criterion = self.criteria[name]!

            var capTimes = criterion.capTimes
            if isVIP {
                capTimes = criterion.capTimes * self.capMultiplier
            }
            var times = UInt64(value / criterion.divisor)
            if times > capTimes {
                times = capTimes
            }

            reward = reward + UFix64(times) * criterion.reward
        }
        return reward
    }

    // Compute final reward in current round with reward cap
    pub fun computeFinalReward(address: Address, totalReward: UFix64): UFix64 {
        var reward = self.userRewards[address] ?? 0.0
        if totalReward > self.rewardCap {
            reward = reward * self.rewardCap / totalReward
        }
        return reward
    }

    pub fun createEmptyMiningReward(): @MiningReward {
        return <- create MiningReward()
    }

    init() {
        self.MiningRewardStoragePath = /storage/bloctoTokenMiningReward
        self.MiningRewardPublicPath = /public/bloctoTokenMiningReward
        self.MiningAdminStoragePath = /storage/bloctoTokenMiningAdmin

        self.miningState = MiningState.initial
        self.currentRound = 0
        self.currentTotalReward = 0.0
        self.rewardCap = 62_500_000.0 / 4.0 / 52.0
        self.capMultiplier = 3
        self.criteria = {}
        self.rewardLockPeriod = 4
        self.rewardLockRatio = 0.5
        self.userRewardsCollected = {}
        self.userRewards = {}
        self.rewardsDistributed = {}

        let admin <- create Administrator()
        self.account.save(<-admin, to: self.MiningAdminStoragePath)
    }
}
