package test

import (
	"strings"
	"testing"

	"github.com/onflow/cadence"
	"github.com/onflow/cadence/encoding/json"
	emulator "github.com/onflow/flow-emulator"
	"github.com/onflow/flow-go-sdk"
	"github.com/onflow/flow-go-sdk/crypto"
	"github.com/onflow/flow-go-sdk/templates"
	"github.com/onflow/flow-go-sdk/test"
	"github.com/stretchr/testify/assert"
)

const (
	bpMiningGetCapMultiplierPath        = projectRootPath + "/scripts/mining/getCapMultiplier.cdc"
	bpMiningGetCriterasPath             = projectRootPath + "/scripts/mining/getCriterias.cdc"
	bpMiningGetCurrentRoundPath         = projectRootPath + "/scripts/mining/getCurrentRound.cdc"
	bpMiningGetCurrentTotalRewardPath   = projectRootPath + "/scripts/mining/getCurrentTotalReward.cdc"
	bpMiningGetMiningStatePath          = projectRootPath + "/scripts/mining/getMiningState.cdc"
	bpMiningGetRewardCapPath            = projectRootPath + "/scripts/mining/getRewardCap.cdc"
	bpMiningGetRewardsDistributedPath   = projectRootPath + "/scripts/mining/getRewardsDistributed.cdc"
	bpMiningGetUserRewardsPath          = projectRootPath + "/scripts/mining/getUserRewards.cdc"
	bpMiningGetUserRewardsCollectedPath = projectRootPath + "/scripts/mining/getUserRewardsCollected.cdc"
	bpMiningCollectDataPath             = projectRootPath + "/transactions/mining/collectData.cdc"
	bpMiningDistributeRewardPath        = projectRootPath + "/transactions/mining/distributeReward.cdc"
	bpMiningFinishDistributingPath      = projectRootPath + "/transactions/mining/finishDistributing.cdc"
	bpMiningGoNextRoundPath             = projectRootPath + "/transactions/mining/goNextRound.cdc"
	bpMiningStartCollectingPath         = projectRootPath + "/transactions/mining/startCollecting.cdc"
	bpMiningStopCollectingPath          = projectRootPath + "/transactions/mining/stopCollecting.cdc"
	bpMiningUpdateCriteriaPath          = projectRootPath + "/transactions/mining/updateCriteria.cdc"
	bpMiningAddDefaultCriteriaPath      = projectRootPath + "/transactions/mining/addDefaultCriteria.cdc"
	bpMiningRemoveCriteriaPath          = projectRootPath + "/transactions/mining/removeCriteria.cdc"
	bpMiningUpdateRewardCapPath         = projectRootPath + "/transactions/mining/updateRewardCap.cdc"
)

type TestBloctoTokenMiningContractsInfo struct {
	FTAddr          flow.Address
	NFTAddr         flow.Address
	BTAddr          flow.Address
	BTSigner        crypto.Signer
	BTStakingAddr   flow.Address
	BTStakingSigner crypto.Signer
	BPAddr          flow.Address
	BPSigner        crypto.Signer
	BPMiningAddr    flow.Address
	BPMiningSigner  crypto.Signer
}

func BloctoTokenMiningDeployContract(b *emulator.Blockchain, t *testing.T) TestBloctoTokenMiningContractsInfo {
	accountKeys := test.AccountKeyGenerator()

	bpInfo := BloctoPassDeployContract(b, t)

	bloctoTokenMiningAccountKey, bloctoTokenMiningSigner := accountKeys.NewWithSigner()
	bloctoTokenMiningCode := loadBloctoTokenMining(bpInfo)

	bloctoTokenMiningAddr, err := b.CreateAccount(
		[]*flow.AccountKey{bloctoTokenMiningAccountKey},
		[]templates.Contract{{
			Name:   "BloctoTokenMining",
			Source: string(bloctoTokenMiningCode),
		}},
	)
	assert.NoError(t, err)

	_, err = b.CommitBlock()
	assert.NoError(t, err)

	return TestBloctoTokenMiningContractsInfo{
		FTAddr:          bpInfo.FTAddr,
		NFTAddr:         bpInfo.NFTAddr,
		BTAddr:          bpInfo.BTAddr,
		BTSigner:        bpInfo.BTSigner,
		BTStakingAddr:   bpInfo.BTStakingAddr,
		BTStakingSigner: bpInfo.BTStakingSigner,
		BPAddr:          bpInfo.BPAddr,
		BPSigner:        bpInfo.BPSigner,
		BPMiningAddr:    bloctoTokenMiningAddr,
		BPMiningSigner:  bloctoTokenMiningSigner,
	}
}

func TestBPMiningDeployment(t *testing.T) {
	b := newEmulator()

	btMiningInfo := BloctoTokenMiningDeployContract(b, t)

	t.Run("Should have initialized mining state correctly", func(t *testing.T) {
		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BPMiningAddr), nil)
		expected := []cadence.Value{cadence.NewUInt8(0)}
		assert.Equal(t, expected, miningState.(cadence.Enum).Fields)
	})

	t.Run("Should have initialized current round correctly", func(t *testing.T) {
		currentRound := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentRoundPath, btMiningInfo.BPMiningAddr), nil)
		expected := cadence.NewUInt64(0)
		assert.Equal(t, expected, currentRound.(cadence.UInt64))
	})

	t.Run("Should have initialized current total reward correctly", func(t *testing.T) {
		currentTotalReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentTotalRewardPath, btMiningInfo.BPMiningAddr), nil)
		expected, err := cadence.NewUFix64("0.0")
		assert.NoError(t, err)
		assert.Equal(t, expected, currentTotalReward.(cadence.UFix64))
	})

	t.Run("Should have initialized reward cap correctly", func(t *testing.T) {
		rewardCap := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetRewardCapPath, btMiningInfo.BPMiningAddr), nil)
		expected, err := cadence.NewUFix64("3004807.69230769")
		assert.NoError(t, err)
		assert.Equal(t, expected, rewardCap.(cadence.UFix64))
	})

	t.Run("Should have initialized cap multiplier correctly", func(t *testing.T) {
		capMultiplier := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCapMultiplierPath, btMiningInfo.BPMiningAddr), nil)
		expected := cadence.NewUInt64(3)
		assert.Equal(t, expected, capMultiplier.(cadence.UInt64))
	})
}

func TestBPMiningMiningState(t *testing.T) {
	b := newEmulator()

	btMiningInfo := BloctoTokenMiningDeployContract(b, t)

	t.Run("Should have Collecting state", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningStartCollectingTransaction(btMiningInfo.BPMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BPMiningAddr), nil)
		miningStateExpected := []cadence.Value{cadence.NewUInt8(1)} // collecting
		assert.Equal(t, miningStateExpected, miningState.(cadence.Enum).Fields)
	})

	t.Run("Should have Collected state", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningStopCollectingTransaction(btMiningInfo.BPMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BPMiningAddr), nil)

		expected := []cadence.Value{cadence.NewUInt8(2)} // collected
		assert.Equal(t, expected, miningState.(cadence.Enum).Fields)
	})

	t.Run("Should have Distributed state", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningFinishDistributingTransaction(btMiningInfo.BPMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BPMiningAddr), nil)

		expected := []cadence.Value{cadence.NewUInt8(3)} // distributed
		assert.Equal(t, expected, miningState.(cadence.Enum).Fields)
	})

	t.Run("Should have Collecting state after going next round", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningGoNextRoundTransaction(btMiningInfo.BPMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BPMiningAddr), nil)
		miningStateExpected := []cadence.Value{cadence.NewUInt8(1)} // collecting
		assert.Equal(t, miningStateExpected, miningState.(cadence.Enum).Fields)
	})
}

func TestBPMiningUpdateCriteria(t *testing.T) {
	b := newEmulator()

	btMiningInfo := BloctoTokenMiningDeployContract(b, t)

	t.Run("Should add criteria correctly", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningUpdateCriteriaTransaction(btMiningInfo.BPMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr)

		_ = tx.AddArgument(cadence.NewString("tx"))
		_ = tx.AddArgument(CadenceUFix64("2.3"))
		_ = tx.AddArgument(CadenceUFix64("100.0"))
		_ = tx.AddArgument(cadence.NewUInt64(123))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			false,
		)

		criteras := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCriterasPath, btMiningInfo.BPMiningAddr), nil)

		expected := make(map[interface{}]interface{})
		expected["tx"] = []interface{}{
			uint64(230000000),
			uint64(10000000000),
			uint64(123),
		}

		assert.Equal(t, expected, criteras.ToGoValue())
	})

	t.Run("Should update criteria correctly", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningUpdateCriteriaTransaction(btMiningInfo.BPMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr)

		_ = tx.AddArgument(cadence.NewString("tx"))
		_ = tx.AddArgument(CadenceUFix64("4.7"))
		_ = tx.AddArgument(CadenceUFix64("101.0"))
		_ = tx.AddArgument(cadence.NewUInt64(321))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			false,
		)

		criteras := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCriterasPath, btMiningInfo.BPMiningAddr), nil)

		expected := make(map[interface{}]interface{})
		expected["tx"] = []interface{}{
			uint64(470000000),
			uint64(10100000000),
			uint64(321),
		}

		assert.Equal(t, expected, criteras.ToGoValue())
	})

	t.Run("Should remove criteria correctly", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningRemoveCriteriaTransaction(btMiningInfo.BPMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr)

		_ = tx.AddArgument(cadence.NewString("tx"))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			false,
		)

		criteras := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCriterasPath, btMiningInfo.BPMiningAddr), nil)

		expected := make(map[interface{}]interface{})
		assert.Equal(t, expected, criteras.ToGoValue())
	})

	t.Run("Shouldn't be able to add criteria when collecting", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningStartCollectingTransaction(btMiningInfo.BPMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BPMiningAddr), nil)
		miningStateExpected := []cadence.Value{cadence.NewUInt8(1)} // collecting
		assert.Equal(t, miningStateExpected, miningState.(cadence.Enum).Fields)

		tx = flow.NewTransaction().
			SetScript(btMiningUpdateCriteriaTransaction(btMiningInfo.BPMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr)

		_ = tx.AddArgument(cadence.NewString("tx"))
		_ = tx.AddArgument(CadenceUFix64("2.3"))
		_ = tx.AddArgument(CadenceUFix64("100.0"))
		_ = tx.AddArgument(cadence.NewUInt64(123))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			true,
		)
	})
}

func TestBPMiningOneRound(t *testing.T) {
	b := newEmulator()

	btMiningInfo := BloctoTokenMiningDeployContract(b, t)

	accountKeys := test.AccountKeyGenerator()
	user1AccountKey, user1Signer := accountKeys.NewWithSigner()
	user1Addr, err := b.CreateAccount(
		[]*flow.AccountKey{user1AccountKey},
		nil,
	)
	assert.NoError(t, err)
	// Add Blocto Pass
	MintNewBloctoPass(t, b, btMiningInfo.NFTAddr, user1Addr, user1Signer, btMiningInfo.BPAddr, btMiningInfo.BPSigner)

	user2AccountKey, user2Signer := accountKeys.NewWithSigner()
	user2Addr, err := b.CreateAccount(
		[]*flow.AccountKey{user2AccountKey},
		nil,
	)
	assert.NoError(t, err)
	// Add Blocto Pass
	MintNewBloctoPass(t, b, btMiningInfo.NFTAddr, user2Addr, user2Signer, btMiningInfo.BPAddr, btMiningInfo.BPSigner)
	// TODO: user2 has BloctoPass on VIP tier 1

	var user1AddrBytes, user2AddrBytes [8]byte
	copy(user1AddrBytes[:], user1Addr.Bytes())
	copy(user2AddrBytes[:], user2Addr.Bytes())

	t.Run("Should be able to add default criteria correctly", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningAddDefaultCriteriaTransaction(btMiningInfo.BPMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			false,
		)

		criteras := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCriterasPath, btMiningInfo.BPMiningAddr), nil)

		expected := make(map[interface{}]interface{})
		expected["tx"] = []interface{}{
			uint64(100000000),
			uint64(100000000),
			uint64(5),
		}
		expected["referral"] = []interface{}{
			uint64(500000000),
			uint64(100000000),
			uint64(6),
		}
		expected["assetInCirculation"] = []interface{}{
			uint64(100000000),
			uint64(10000000000),
			uint64(10),
		}

		assert.Equal(t, expected, criteras.ToGoValue())
	})

	t.Run("Should be able to go first round", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningGoNextRoundTransaction(btMiningInfo.BPMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BPMiningAddr), nil)
		miningStateExpected := []cadence.Value{cadence.NewUInt8(1)} // collecting
		assert.Equal(t, miningStateExpected, miningState.(cadence.Enum).Fields)

		currentRound := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentRoundPath, btMiningInfo.BPMiningAddr), nil)
		currentRoundExpected := cadence.NewUInt64(1)
		assert.Equal(t, currentRoundExpected, currentRound)

		currentTotalReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentTotalRewardPath, btMiningInfo.BPMiningAddr), nil)
		currentTotalRewardExpected, err := cadence.NewUFix64("0.0")
		assert.NoError(t, err)
		assert.Equal(t, currentTotalRewardExpected, currentTotalReward)
	})

	t.Run("Should be able to collect data", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningCollectDataTransaction(btMiningInfo.BPMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr)

		_ = tx.AddArgument(cadence.NewAddress(user1Addr))
		_ = tx.AddArgument(CadenceUFix64("1.0"))
		_ = tx.AddArgument(CadenceUFix64("2.0"))
		_ = tx.AddArgument(CadenceUFix64("300.0"))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			false,
		)

		currentTotalReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentTotalRewardPath, btMiningInfo.BPMiningAddr), nil)
		currentTotalRewardExpected, err := cadence.NewUFix64("14.0")
		assert.NoError(t, err)
		assert.Equal(t, currentTotalRewardExpected, currentTotalReward)

		usersReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetUserRewardsPath, btMiningInfo.BPMiningAddr), nil)
		usersRewardExpected := make(map[interface{}]interface{})
		user1Addr.Bytes()
		usersRewardExpected[user1AddrBytes] = uint64(1400000000)
		assert.Equal(t, usersRewardExpected, usersReward.ToGoValue())

		userRewardsCollected := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetUserRewardsCollectedPath, btMiningInfo.BPMiningAddr), nil)
		userRewardsCollectedExpected := make(map[interface{}]interface{})
		userRewardsCollectedExpected[user1AddrBytes] = uint64(1)
		assert.Equal(t, userRewardsCollectedExpected, userRewardsCollected.ToGoValue())
	})

	t.Run("Should be able to collect data instead of old data", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningCollectDataTransaction(btMiningInfo.BPMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr)

		_ = tx.AddArgument(cadence.NewAddress(user1Addr))
		_ = tx.AddArgument(CadenceUFix64("2.0"))
		_ = tx.AddArgument(CadenceUFix64("3.0"))
		_ = tx.AddArgument(CadenceUFix64("500.0"))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			false,
		)

		currentTotalReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentTotalRewardPath, btMiningInfo.BPMiningAddr), nil)
		currentTotalRewardExpected, err := cadence.NewUFix64("22.0")
		assert.NoError(t, err)
		assert.Equal(t, currentTotalRewardExpected, currentTotalReward)

		usersReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetUserRewardsPath, btMiningInfo.BPMiningAddr), nil)
		usersRewardExpected := make(map[interface{}]interface{})
		user1Addr.Bytes()
		usersRewardExpected[user1AddrBytes] = uint64(2200000000)
		assert.Equal(t, usersRewardExpected, usersReward.ToGoValue())

		userRewardsCollected := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetUserRewardsCollectedPath, btMiningInfo.BPMiningAddr), nil)
		userRewardsCollectedExpected := make(map[interface{}]interface{})
		userRewardsCollectedExpected[user1AddrBytes] = uint64(1)
		assert.Equal(t, userRewardsCollectedExpected, userRewardsCollected.ToGoValue())
	})

	t.Run("Should be able to collect data with VIP-tier Blocto Pass", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningCollectDataTransaction(btMiningInfo.BPMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr)

		_ = tx.AddArgument(cadence.NewAddress(user2Addr))
		_ = tx.AddArgument(CadenceUFix64("2.0"))
		_ = tx.AddArgument(CadenceUFix64("15.0"))
		_ = tx.AddArgument(CadenceUFix64("50.0"))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			false,
		)

		currentTotalReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentTotalRewardPath, btMiningInfo.BPMiningAddr), nil)
		currentTotalRewardExpected, err := cadence.NewUFix64("54.0")
		assert.NoError(t, err)
		assert.Equal(t, currentTotalRewardExpected, currentTotalReward)

		usersReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetUserRewardsPath, btMiningInfo.BPMiningAddr), nil)
		usersRewardExpected := make(map[interface{}]interface{})
		usersRewardExpected[user1AddrBytes] = uint64(2200000000)
		usersRewardExpected[user2AddrBytes] = uint64(3200000000)
		assert.Equal(t, usersRewardExpected, usersReward.ToGoValue())

		userRewardsCollected := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetUserRewardsCollectedPath, btMiningInfo.BPMiningAddr), nil)
		userRewardsCollectedExpected := make(map[interface{}]interface{})
		userRewardsCollectedExpected[user1AddrBytes] = uint64(1)
		userRewardsCollectedExpected[user2AddrBytes] = uint64(1)
		assert.Equal(t, userRewardsCollectedExpected, userRewardsCollected.ToGoValue())
	})

	t.Run("Should be able to stop collecting correctly", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningStopCollectingTransaction(btMiningInfo.BPMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BPMiningAddr), nil)
		expected := []cadence.Value{cadence.NewUInt8(2)} // collected
		assert.Equal(t, expected, miningState.(cadence.Enum).Fields)
	})

	t.Run("Should be able to distribute rewards correctly", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningDistributeRewardTransaction(btMiningInfo.BPMiningAddr, btMiningInfo.BTAddr)).
			SetGasLimit(150).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr).
			AddAuthorizer(btMiningInfo.BTAddr)

		_ = tx.AddArgument(cadence.NewAddress(user1Addr))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr, btMiningInfo.BTAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner, btMiningInfo.BTSigner},
			false,
		)

		reward := executeScriptAndCheck(t, b,
			bpGetBloctoPassVaultBalanceScript(btMiningInfo.BPAddr, btMiningInfo.NFTAddr),
			[][]byte{json.MustEncode(cadence.Address(user1Addr))})
		rewardExpected, _ := cadence.NewUFix64("22.0")
		assert.Equal(t, rewardExpected, reward)

		rewardDistributed := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetRewardsDistributedPath, btMiningInfo.BPMiningAddr), nil)
		rewardDistributedExpected := make(map[interface{}]interface{})
		rewardDistributedExpected[user1AddrBytes] = uint64(1)
		assert.Equal(t, rewardDistributedExpected, rewardDistributed.ToGoValue())
	})

	t.Run("Should be able to prevent distributing reward repeatedly", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningDistributeRewardTransaction(btMiningInfo.BPMiningAddr, btMiningInfo.BTAddr)).
			SetGasLimit(150).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr).
			AddAuthorizer(btMiningInfo.BTAddr)

		_ = tx.AddArgument(cadence.NewAddress(user1Addr))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			true,
		)
	})

	t.Run("Should be able to distribute rewards correctly for user 2", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningDistributeRewardTransaction(btMiningInfo.BPMiningAddr, btMiningInfo.BTAddr)).
			SetGasLimit(150).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr).
			AddAuthorizer(btMiningInfo.BTAddr)

		_ = tx.AddArgument(cadence.NewAddress(user2Addr))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr, btMiningInfo.BTAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner, btMiningInfo.BTSigner},
			false,
		)

		reward := executeScriptAndCheck(t, b,
			bpGetBloctoPassVaultBalanceScript(btMiningInfo.BPAddr, btMiningInfo.NFTAddr),
			[][]byte{json.MustEncode(cadence.Address(user2Addr))})
		rewardExpected, _ := cadence.NewUFix64("32.0")
		assert.Equal(t, rewardExpected, reward)

		rewardDistributed := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetRewardsDistributedPath, btMiningInfo.BPMiningAddr), nil)
		rewardDistributedExpected := make(map[interface{}]interface{})
		rewardDistributedExpected[user1AddrBytes] = uint64(1)
		rewardDistributedExpected[user2AddrBytes] = uint64(1)
		assert.Equal(t, rewardDistributedExpected, rewardDistributed.ToGoValue())
	})

	t.Run("Should be able to finish distributing correctly", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningFinishDistributingTransaction(btMiningInfo.BPMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BPMiningAddr), nil)
		expected := []cadence.Value{cadence.NewUInt8(3)} // distributed
		assert.Equal(t, expected, miningState.(cadence.Enum).Fields)
	})

	t.Run("Should have Collecting state after going next round", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningGoNextRoundTransaction(btMiningInfo.BPMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BPMiningAddr), nil)
		miningStateExpected := []cadence.Value{cadence.NewUInt8(1)} // collecting
		assert.Equal(t, miningStateExpected, miningState.(cadence.Enum).Fields)

		currentRound := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentRoundPath, btMiningInfo.BPMiningAddr), nil)
		currentRoundExpected := cadence.NewUInt64(2)
		assert.Equal(t, currentRoundExpected, currentRound.(cadence.UInt64))
	})
}

func TestBPMiningOneRoundOverRewardCap(t *testing.T) {
	b := newEmulator()

	btMiningInfo := BloctoTokenMiningDeployContract(b, t)

	accountKeys := test.AccountKeyGenerator()
	user1AccountKey, user1Signer := accountKeys.NewWithSigner()
	user1Addr, err := b.CreateAccount(
		[]*flow.AccountKey{user1AccountKey},
		nil,
	)
	assert.NoError(t, err)
	// Add Blocto Pass
	MintNewBloctoPass(t, b, btMiningInfo.NFTAddr, user1Addr, user1Signer, btMiningInfo.BPAddr, btMiningInfo.BPSigner)

	user2AccountKey, user2Signer := accountKeys.NewWithSigner()
	user2Addr, err := b.CreateAccount(
		[]*flow.AccountKey{user2AccountKey},
		nil,
	)
	assert.NoError(t, err)
	// Add Blocto Pass
	MintNewBloctoPass(t, b, btMiningInfo.NFTAddr, user2Addr, user2Signer, btMiningInfo.BPAddr, btMiningInfo.BPSigner)
	// TODO: user2 has BloctoPass on VIP tier 1

	var user1AddrBytes, user2AddrBytes [8]byte
	copy(user1AddrBytes[:], user1Addr.Bytes())
	copy(user2AddrBytes[:], user2Addr.Bytes())

	t.Run("Should be able to add default criteria correctly", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningAddDefaultCriteriaTransaction(btMiningInfo.BPMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			false,
		)

		criteras := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCriterasPath, btMiningInfo.BPMiningAddr), nil)

		expected := make(map[interface{}]interface{})
		expected["tx"] = []interface{}{
			uint64(100000000),
			uint64(100000000),
			uint64(5),
		}
		expected["referral"] = []interface{}{
			uint64(500000000),
			uint64(100000000),
			uint64(6),
		}
		expected["assetInCirculation"] = []interface{}{
			uint64(100000000),
			uint64(10000000000),
			uint64(10),
		}

		assert.Equal(t, expected, criteras.ToGoValue())
	})

	t.Run("Should be able to update reward cap correctly", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningUpdateRewardCapTransaction(btMiningInfo.BPMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr)

		rewardCap, err := cadence.NewUFix64("10.1231")
		assert.NoError(t, err)
		_ = tx.AddArgument(rewardCap)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			false,
		)

		newRewardCap := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetRewardCapPath, btMiningInfo.BPMiningAddr), nil)
		assert.Equal(t, rewardCap, newRewardCap)
	})

	t.Run("Should be able to go first round", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningGoNextRoundTransaction(btMiningInfo.BPMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BPMiningAddr), nil)
		miningStateExpected := []cadence.Value{cadence.NewUInt8(1)} // collecting
		assert.Equal(t, miningStateExpected, miningState.(cadence.Enum).Fields)

		currentRound := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentRoundPath, btMiningInfo.BPMiningAddr), nil)
		currentRoundExpected := cadence.NewUInt64(1)
		assert.Equal(t, currentRoundExpected, currentRound)

		currentTotalReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentTotalRewardPath, btMiningInfo.BPMiningAddr), nil)
		currentTotalRewardExpected, err := cadence.NewUFix64("0.0")
		assert.NoError(t, err)
		assert.Equal(t, currentTotalRewardExpected, currentTotalReward)
	})

	t.Run("Should be able to collect data", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningCollectDataTransaction(btMiningInfo.BPMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr)

		_ = tx.AddArgument(cadence.NewAddress(user1Addr))
		_ = tx.AddArgument(CadenceUFix64("2.0"))
		_ = tx.AddArgument(CadenceUFix64("3.0"))
		_ = tx.AddArgument(CadenceUFix64("500.0"))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			false,
		)

		currentTotalReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentTotalRewardPath, btMiningInfo.BPMiningAddr), nil)
		currentTotalRewardExpected, err := cadence.NewUFix64("22.0")
		assert.NoError(t, err)
		assert.Equal(t, currentTotalRewardExpected, currentTotalReward)

		usersReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetUserRewardsPath, btMiningInfo.BPMiningAddr), nil)
		usersRewardExpected := make(map[interface{}]interface{})
		user1Addr.Bytes()
		usersRewardExpected[user1AddrBytes] = uint64(2200000000)
		assert.Equal(t, usersRewardExpected, usersReward.ToGoValue())

		userRewardsCollected := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetUserRewardsCollectedPath, btMiningInfo.BPMiningAddr), nil)
		userRewardsCollectedExpected := make(map[interface{}]interface{})
		userRewardsCollectedExpected[user1AddrBytes] = uint64(1)
		assert.Equal(t, userRewardsCollectedExpected, userRewardsCollected.ToGoValue())
	})

	t.Run("Should be able to collect data with VIP-tier Blocto Pass", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningCollectDataTransaction(btMiningInfo.BPMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr)

		_ = tx.AddArgument(cadence.NewAddress(user2Addr))
		_ = tx.AddArgument(CadenceUFix64("2.0"))
		_ = tx.AddArgument(CadenceUFix64("15.0"))
		_ = tx.AddArgument(CadenceUFix64("50.0"))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			false,
		)

		currentTotalReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentTotalRewardPath, btMiningInfo.BPMiningAddr), nil)
		currentTotalRewardExpected, err := cadence.NewUFix64("54.0")
		assert.NoError(t, err)
		assert.Equal(t, currentTotalRewardExpected, currentTotalReward)

		usersReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetUserRewardsPath, btMiningInfo.BPMiningAddr), nil)
		usersRewardExpected := make(map[interface{}]interface{})
		usersRewardExpected[user1AddrBytes] = uint64(2200000000)
		usersRewardExpected[user2AddrBytes] = uint64(3200000000)
		assert.Equal(t, usersRewardExpected, usersReward.ToGoValue())

		userRewardsCollected := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetUserRewardsCollectedPath, btMiningInfo.BPMiningAddr), nil)
		userRewardsCollectedExpected := make(map[interface{}]interface{})
		userRewardsCollectedExpected[user1AddrBytes] = uint64(1)
		userRewardsCollectedExpected[user2AddrBytes] = uint64(1)
		assert.Equal(t, userRewardsCollectedExpected, userRewardsCollected.ToGoValue())
	})

	t.Run("Should be able to stop collecting correctly", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningStopCollectingTransaction(btMiningInfo.BPMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BPMiningAddr), nil)
		expected := []cadence.Value{cadence.NewUInt8(2)} // collected
		assert.Equal(t, expected, miningState.(cadence.Enum).Fields)
	})

	t.Run("Should be able to distribute rewards correctly", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningDistributeRewardTransaction(btMiningInfo.BPMiningAddr, btMiningInfo.BTAddr)).
			SetGasLimit(150).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr).
			AddAuthorizer(btMiningInfo.BTAddr)

		_ = tx.AddArgument(cadence.NewAddress(user1Addr))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr, btMiningInfo.BTAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner, btMiningInfo.BTSigner},
			false,
		)

		reward := executeScriptAndCheck(t, b,
			bpGetBloctoPassVaultBalanceScript(btMiningInfo.BPAddr, btMiningInfo.NFTAddr),
			[][]byte{json.MustEncode(cadence.Address(user1Addr))})
		rewardExpected, _ := cadence.NewUFix64("4.12422592")
		assert.Equal(t, rewardExpected, reward)

		rewardDistributed := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetRewardsDistributedPath, btMiningInfo.BPMiningAddr), nil)
		rewardDistributedExpected := make(map[interface{}]interface{})
		rewardDistributedExpected[user1AddrBytes] = uint64(1)
		assert.Equal(t, rewardDistributedExpected, rewardDistributed.ToGoValue())
	})

	t.Run("Should be able to distribute rewards correctly for user 2", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningDistributeRewardTransaction(btMiningInfo.BPMiningAddr, btMiningInfo.BTAddr)).
			SetGasLimit(150).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr).
			AddAuthorizer(btMiningInfo.BTAddr)

		_ = tx.AddArgument(cadence.NewAddress(user2Addr))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr, btMiningInfo.BTAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner, btMiningInfo.BTSigner},
			false,
		)

		reward := executeScriptAndCheck(t, b,
			bpGetBloctoPassVaultBalanceScript(btMiningInfo.BPAddr, btMiningInfo.NFTAddr),
			[][]byte{json.MustEncode(cadence.Address(user2Addr))})
		rewardExpected, _ := cadence.NewUFix64("5.99887407")
		assert.Equal(t, rewardExpected, reward)

		rewardDistributed := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetRewardsDistributedPath, btMiningInfo.BPMiningAddr), nil)
		rewardDistributedExpected := make(map[interface{}]interface{})
		rewardDistributedExpected[user1AddrBytes] = uint64(1)
		rewardDistributedExpected[user2AddrBytes] = uint64(1)
		assert.Equal(t, rewardDistributedExpected, rewardDistributed.ToGoValue())
	})

	t.Run("Should be able to finish distributing correctly", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningFinishDistributingTransaction(btMiningInfo.BPMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BPMiningAddr), nil)
		expected := []cadence.Value{cadence.NewUInt8(3)} // distributed
		assert.Equal(t, expected, miningState.(cadence.Enum).Fields)
	})

	t.Run("Should have Collecting state after going next round", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningGoNextRoundTransaction(btMiningInfo.BPMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BPMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BPMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BPMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BPMiningAddr), nil)
		miningStateExpected := []cadence.Value{cadence.NewUInt8(1)} // collecting
		assert.Equal(t, miningStateExpected, miningState.(cadence.Enum).Fields)

		currentRound := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentRoundPath, btMiningInfo.BPMiningAddr), nil)
		currentRoundExpected := cadence.NewUInt64(2)
		assert.Equal(t, currentRoundExpected, currentRound.(cadence.UInt64))
	})
}

func loadBloctoTokenMining(bpInfo TestBloctoPassContractsInfo) []byte {
	code := string(readFile(bloctoTokenMiningPath))

	code = strings.ReplaceAll(code, "\"../token/FungibleToken.cdc\"", "0x"+bpInfo.FTAddr.String())
	code = strings.ReplaceAll(code, "\"../token/NonFungibleToken.cdc\"", "0x"+bpInfo.NFTAddr.String())
	code = strings.ReplaceAll(code, "\"../token/BloctoToken.cdc\"", "0x"+bpInfo.BTAddr.String())
	code = strings.ReplaceAll(code, "\"../token/BloctoPass.cdc\"", "0x"+bpInfo.BPAddr.String())

	return []byte(code)
}

func btMiningGetPropertyScript(filename string, btMiningAddr flow.Address) []byte {
	return []byte(strings.ReplaceAll(
		string(readFile(filename)),
		"\"../../contracts/flow/mining/BloctoTokenMining.cdc\"",
		"0x"+btMiningAddr.String(),
	))
}

func btMiningCollectDataTransaction(btMiningAddr flow.Address) []byte {
	return []byte(strings.ReplaceAll(
		string(readFile(bpMiningCollectDataPath)),
		"\"../../contracts/flow/mining/BloctoTokenMining.cdc\"",
		"0x"+btMiningAddr.String(),
	))
}

func btMiningDistributeRewardTransaction(btMiningAddr flow.Address, btAddr flow.Address) []byte {
	code := string(readFile(bpMiningDistributeRewardPath))

	code = strings.ReplaceAll(code, "\"../../contracts/flow/token/BloctoToken.cdc\"", "0x"+btAddr.String())
	code = strings.ReplaceAll(code, "\"../../contracts/flow/mining/BloctoTokenMining.cdc\"", "0x"+btMiningAddr.String())

	return []byte(code)
}

func btMiningFinishDistributingTransaction(btMiningAddr flow.Address) []byte {
	return []byte(strings.ReplaceAll(
		string(readFile(bpMiningFinishDistributingPath)),
		"\"../../contracts/flow/mining/BloctoTokenMining.cdc\"",
		"0x"+btMiningAddr.String(),
	))
}

func btMiningGoNextRoundTransaction(btMiningAddr flow.Address) []byte {
	return []byte(strings.ReplaceAll(
		string(readFile(bpMiningGoNextRoundPath)),
		"\"../../contracts/flow/mining/BloctoTokenMining.cdc\"",
		"0x"+btMiningAddr.String(),
	))
}

func btMiningStartCollectingTransaction(btMiningAddr flow.Address) []byte {
	return []byte(strings.ReplaceAll(
		string(readFile(bpMiningStartCollectingPath)),
		"\"../../contracts/flow/mining/BloctoTokenMining.cdc\"",
		"0x"+btMiningAddr.String(),
	))
}

func btMiningStopCollectingTransaction(btMiningAddr flow.Address) []byte {
	return []byte(strings.ReplaceAll(
		string(readFile(bpMiningStopCollectingPath)),
		"\"../../contracts/flow/mining/BloctoTokenMining.cdc\"",
		"0x"+btMiningAddr.String(),
	))
}

func btMiningAddDefaultCriteriaTransaction(btMiningAddr flow.Address) []byte {
	return []byte(strings.ReplaceAll(
		string(readFile(bpMiningAddDefaultCriteriaPath)),
		"\"../../contracts/flow/mining/BloctoTokenMining.cdc\"",
		"0x"+btMiningAddr.String(),
	))
}

func btMiningUpdateCriteriaTransaction(btMiningAddr flow.Address) []byte {
	return []byte(strings.ReplaceAll(
		string(readFile(bpMiningUpdateCriteriaPath)),
		"\"../../contracts/flow/mining/BloctoTokenMining.cdc\"",
		"0x"+btMiningAddr.String(),
	))
}

func btMiningRemoveCriteriaTransaction(btMiningAddr flow.Address) []byte {
	return []byte(strings.ReplaceAll(
		string(readFile(bpMiningRemoveCriteriaPath)),
		"\"../../contracts/flow/mining/BloctoTokenMining.cdc\"",
		"0x"+btMiningAddr.String(),
	))
}

func btMiningUpdateRewardCapTransaction(btMiningAddr flow.Address) []byte {
	return []byte(strings.ReplaceAll(
		string(readFile(bpMiningUpdateRewardCapPath)),
		"\"../../contracts/flow/mining/BloctoTokenMining.cdc\"",
		"0x"+btMiningAddr.String(),
	))
}
