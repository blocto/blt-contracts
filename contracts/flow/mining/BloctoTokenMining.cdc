import FungibleToken from "../token/FungibleToken.cdc"
import NonFungibleToken from "../token/NonFungibleToken.cdc"
import BloctoToken from "../token/BloctoToken.cdc"
import BloctoPass from "../token/BloctoPass.cdc"

pub contract BloctoTokenMining {

    // Define mining state
    pub var miningState: MiningState

    // Define current round
    pub var currentRound: UInt64

    // Define current total reward computed by users' raw data
    pub var currentTotalReward: UFix64

    // Define reward cap
    pub var rewardCap: UFix64

    // Define cap multipier for VIP-tier users
    pub var capMultiplier: UInt64

    // Define mining criterias
    // criteria name => Criteria
    pub var criterias: {String: Criteria}

    // Define if user reward is collected
    // Address => round
    pub var userRewardsCollected: {Address: UInt64}

    // Define user rewards in current round
    // This doesn't consider reward cap
    pub var userRewards: {Address: UFix64}

    // Define if reward is distributed
    // Address => round
    pub var rewardsDistributed: {Address: UInt64}

    // Event that is emitted when mining state is updated
    pub event MiningStateUpdated(state: UInt8)

    // Event that is emitted when go to next round
    pub event RoundUpdated(round: UInt64)

    // Event that is emitted when reward cap is updated
    pub event RewardCapUpdated(rewardCap: UFix64)

    // Event that is emitted when cap multiplier is updated
    pub event CapMultiplierUpdated(capMultiplier: UInt64)

    // Event that is emitted when new criteria is updated
    pub event CriteriaUpdated(name: String, criteria: Criteria?)

    // Event that is emitted when mining raw data is collected
    pub event DataCollected(data: {String: UFix64}, address: Address, reward: UFix64, replacedReward: UFix64?)

    // Event that is emitted when reward is distributed
    pub event RewardDistributed(reward: UFix64, address: Address)

    // Criteria
    //
    // Define mining criteria
    //
    pub struct Criteria {

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

        // Update criteria by name
        pub fun updateCriteria(name: String, criteria: Criteria?) {
            pre {
                BloctoTokenMining.miningState == MiningState.initial ||
                    BloctoTokenMining.miningState == MiningState.collected:
                    "Current round should be collected"
            }
            BloctoTokenMining.criterias[name] = criteria

            emit CriteriaUpdated(name: name, criteria: criteria)
        }

        // Collect raw data
        // data: {criteria name: raw data}
        pub fun collectData(_ data: {String: UFix64}, address: Address) {
            pre {
                BloctoTokenMining.miningState == MiningState.collecting: "Should start collecting"
            }

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
        pub fun distributeReward(address: Address, rewardVault: @BloctoToken.Vault) {
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
            if rewardVault.balance != reward {
                panic("The balance of reward vault must be the same as reward")
            }

            let bloctoPass = self.getHighestTierBloctoPass(address: address)
                ?? panic("Could not find blocto pass")
            let collectionRef = getAccount(address).getCapability(/public/bloctoPassCollection)
                .borrow<&{BloctoPass.CollectionPublic}>()
                ?? panic("Could not borrow blocto pass collection public reference")
            let amount = rewardVault.balance
            collectionRef.depositBloctoToken(from: <- rewardVault, id: bloctoPass.id)

            BloctoTokenMining.rewardsDistributed[address] = BloctoTokenMining.currentRound

            emit RewardDistributed(reward: amount, address: address)
        }

        access(self) fun getHighestTierBloctoPass(address: Address): &BloctoPass.NFT? {
            let collectionRef = getAccount(address).getCapability(/public/bloctoPassCollection)
                .borrow<&{NonFungibleToken.CollectionPublic, BloctoPass.CollectionPublic}>()
                ?? panic("Could not borrow collection public reference")

            var highestTier: UInt64? = nil
            var highestBloctoPass: &BloctoPass.NFT? = nil
            for id in collectionRef.getIDs() {
                let bloctoPass = collectionRef.borrowBloctoPass(id: id)
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

    // Chceck if the address is VIP
    pub fun isAddressVIP(address: Address): Bool {
        let collectionRef = getAccount(address).getCapability(/public/bloctoPassCollection)
            .borrow<&{NonFungibleToken.CollectionPublic, BloctoPass.CollectionPublic}>()
            ?? panic("Could not borrow collection public reference")

        for id in collectionRef.getIDs() {
            let bloctoPass = collectionRef.borrowBloctoPass(id: id)
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
            let criteria = self.criterias[name]!

            var capTimes = criteria.capTimes
            if isVIP {
                capTimes = criteria.capTimes * self.capMultiplier
            }
            var times = UInt64(value / criteria.divisor)
            if times > capTimes {
                times = capTimes
            }

            reward = reward + UFix64(times) * criteria.reward
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

    init() {
        self.miningState = MiningState.initial
        self.currentRound = 0
        self.currentTotalReward = 0.0
        self.rewardCap = 625_000_000.0 / 4.0 / 52.0
        self.capMultiplier = 3
        self.criterias = {}
        self.userRewardsCollected = {}
        self.userRewards = {}
        self.rewardsDistributed = {}

        let admin <- create Administrator()
        self.account.save(<-admin, to: /storage/bloctoTokenMiningAdmin)
    }
}
