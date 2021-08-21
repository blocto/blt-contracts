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
	bpMiningGetMiningRewardPath         = projectRootPath + "/scripts/mining/getMiningReward.cdc"
	bpMiningGetMiningStatePath          = projectRootPath + "/scripts/mining/getMiningState.cdc"
	bpMiningGetRewardCapPath            = projectRootPath + "/scripts/mining/getRewardCap.cdc"
	bpMiningGetRewardLockPeriodPath     = projectRootPath + "/scripts/mining/getRewardLockPeriod.cdc"
	bpMiningGetRewardLockRatioPath      = projectRootPath + "/scripts/mining/getRewardLockRatio.cdc"
	bpMiningGetRewardsDistributedPath   = projectRootPath + "/scripts/mining/getRewardsDistributed.cdc"
	bpMiningGetUnlockMiningRewardPath   = projectRootPath + "/scripts/mining/getUnlockMiningReward.cdc"
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
	bpMiningUpdateRewardLockPeriodPath  = projectRootPath + "/transactions/mining/updateRewardLockPeriod.cdc"
	bpMiningUpdateRewardLockRatioPath   = projectRootPath + "/transactions/mining/updateRewardLockRatio.cdc"
	bpMiningSetupMiningRewardPath       = projectRootPath + "/transactions/mining/setupMiningReward.cdc"
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
	BTMiningAddr    flow.Address
	BTMiningSigner  crypto.Signer
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
		BTMiningAddr:    bloctoTokenMiningAddr,
		BTMiningSigner:  bloctoTokenMiningSigner,
	}
}

func BloctoTokenMiningSetupMiningReward(
	t *testing.T, b *emulator.Blockchain, btMiningInfo TestBloctoTokenMiningContractsInfo,
	userAddr flow.Address, userSigner crypto.Signer) {
	tx := flow.NewTransaction().
		SetScript(btMiningSetupMiningRewardTransaction(btMiningInfo.BTMiningAddr)).
		SetGasLimit(100).
		SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
		SetPayer(b.ServiceKey().Address).
		AddAuthorizer(userAddr)

	signAndSubmit(
		t, b, tx,
		[]flow.Address{b.ServiceKey().Address, userAddr},
		[]crypto.Signer{b.ServiceKey().Signer(), userSigner},
		false,
	)
}

func TestBPMiningDeployment(t *testing.T) {
	b := newEmulator()

	btMiningInfo := BloctoTokenMiningDeployContract(b, t)

	t.Run("Should have initialized mining state correctly", func(t *testing.T) {
		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BTMiningAddr), nil)
		expected := []cadence.Value{cadence.NewUInt8(0)}
		assert.Equal(t, expected, miningState.(cadence.Enum).Fields)
	})

	t.Run("Should have initialized current round correctly", func(t *testing.T) {
		currentRound := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentRoundPath, btMiningInfo.BTMiningAddr), nil)
		expected := cadence.NewUInt64(0)
		assert.Equal(t, expected, currentRound.(cadence.UInt64))
	})

	t.Run("Should have initialized current total reward correctly", func(t *testing.T) {
		currentTotalReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentTotalRewardPath, btMiningInfo.BTMiningAddr), nil)
		expected, err := cadence.NewUFix64("0.0")
		assert.NoError(t, err)
		assert.Equal(t, expected, currentTotalReward.(cadence.UFix64))
	})

	t.Run("Should have initialized reward cap correctly", func(t *testing.T) {
		rewardCap := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetRewardCapPath, btMiningInfo.BTMiningAddr), nil)
		expected, err := cadence.NewUFix64("300480.76923076")
		assert.NoError(t, err)
		assert.Equal(t, expected, rewardCap.(cadence.UFix64))
	})

	t.Run("Should have initialized cap multiplier correctly", func(t *testing.T) {
		capMultiplier := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCapMultiplierPath, btMiningInfo.BTMiningAddr), nil)
		expected := cadence.NewUInt64(3)
		assert.Equal(t, expected, capMultiplier.(cadence.UInt64))
	})

	t.Run("Should have initialized reward lock period correctly", func(t *testing.T) {
		rewardLockPeriod := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetRewardLockPeriodPath, btMiningInfo.BTMiningAddr), nil)
		expected := cadence.NewUInt64(4)
		assert.Equal(t, expected, rewardLockPeriod.(cadence.UInt64))
	})

	t.Run("Should have initialized reward lock ratio correctly", func(t *testing.T) {
		rewardLockRatio := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetRewardLockRatioPath, btMiningInfo.BTMiningAddr), nil)
		expected, err := cadence.NewUFix64("0.5")
		assert.NoError(t, err)
		assert.Equal(t, expected, rewardLockRatio.(cadence.UFix64))
	})
}

func TestBPMiningMiningState(t *testing.T) {
	b := newEmulator()

	btMiningInfo := BloctoTokenMiningDeployContract(b, t)

	t.Run("Should have Collecting state", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningStartCollectingTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BTMiningAddr), nil)
		miningStateExpected := []cadence.Value{cadence.NewUInt8(1)} // collecting
		assert.Equal(t, miningStateExpected, miningState.(cadence.Enum).Fields)
	})

	t.Run("Should have Collected state", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningStopCollectingTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BTMiningAddr), nil)

		expected := []cadence.Value{cadence.NewUInt8(2)} // collected
		assert.Equal(t, expected, miningState.(cadence.Enum).Fields)
	})

	t.Run("Should have Distributed state", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningFinishDistributingTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BTMiningAddr), nil)

		expected := []cadence.Value{cadence.NewUInt8(3)} // distributed
		assert.Equal(t, expected, miningState.(cadence.Enum).Fields)
	})

	t.Run("Should have Collecting state after going next round", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningGoNextRoundTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BTMiningAddr), nil)
		miningStateExpected := []cadence.Value{cadence.NewUInt8(1)} // collecting
		assert.Equal(t, miningStateExpected, miningState.(cadence.Enum).Fields)
	})
}

func TestBPMiningUpdateCriteria(t *testing.T) {
	b := newEmulator()

	btMiningInfo := BloctoTokenMiningDeployContract(b, t)

	t.Run("Should add criteria correctly", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningUpdateCriteriaTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		_ = tx.AddArgument(cadence.NewString("tx"))
		_ = tx.AddArgument(CadenceUFix64("2.3"))
		_ = tx.AddArgument(CadenceUFix64("100.0"))
		_ = tx.AddArgument(cadence.NewUInt64(123))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		criteras := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCriterasPath, btMiningInfo.BTMiningAddr), nil)

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
			SetScript(btMiningUpdateCriteriaTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		_ = tx.AddArgument(cadence.NewString("tx"))
		_ = tx.AddArgument(CadenceUFix64("4.7"))
		_ = tx.AddArgument(CadenceUFix64("101.0"))
		_ = tx.AddArgument(cadence.NewUInt64(321))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		criteras := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCriterasPath, btMiningInfo.BTMiningAddr), nil)

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
			SetScript(btMiningRemoveCriteriaTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		_ = tx.AddArgument(cadence.NewString("tx"))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		criteras := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCriterasPath, btMiningInfo.BTMiningAddr), nil)

		expected := make(map[interface{}]interface{})
		assert.Equal(t, expected, criteras.ToGoValue())
	})

	t.Run("Shouldn't be able to add criteria when collecting", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningStartCollectingTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BTMiningAddr), nil)
		miningStateExpected := []cadence.Value{cadence.NewUInt8(1)} // collecting
		assert.Equal(t, miningStateExpected, miningState.(cadence.Enum).Fields)

		tx = flow.NewTransaction().
			SetScript(btMiningUpdateCriteriaTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		_ = tx.AddArgument(cadence.NewString("tx"))
		_ = tx.AddArgument(CadenceUFix64("2.3"))
		_ = tx.AddArgument(CadenceUFix64("100.0"))
		_ = tx.AddArgument(cadence.NewUInt64(123))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			true,
		)
	})
}

func TestBPMiningUpdateRewardLockPeriod(t *testing.T) {
	b := newEmulator()

	btMiningInfo := BloctoTokenMiningDeployContract(b, t)

	t.Run("Should update reward lock period correctly", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningUpdateRewardLockPeriodTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		_ = tx.AddArgument(cadence.NewUInt64(123))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		rewardLockPeriod := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetRewardLockPeriodPath, btMiningInfo.BTMiningAddr), nil)

		expected := cadence.NewUInt64(123)
		assert.Equal(t, expected, rewardLockPeriod.(cadence.UInt64))
	})
}

func TestBPMiningUpdateRewardRatioPeriod(t *testing.T) {
	b := newEmulator()

	btMiningInfo := BloctoTokenMiningDeployContract(b, t)

	t.Run("Should update reward lock ratio correctly", func(t *testing.T) {
		expected, err := cadence.NewUFix64("0.99")
		assert.NoError(t, err)

		tx := flow.NewTransaction().
			SetScript(btMiningUpdateRewardLockRatioTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		_ = tx.AddArgument(expected)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		rewardLockRatio := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetRewardLockRatioPath, btMiningInfo.BTMiningAddr), nil)
		assert.Equal(t, expected, rewardLockRatio.(cadence.UFix64))
	})

	t.Run("Should NOT update reward lock ratio with value > 1", func(t *testing.T) {
		expected, err := cadence.NewUFix64("1.01")
		assert.NoError(t, err)

		tx := flow.NewTransaction().
			SetScript(btMiningUpdateRewardLockRatioTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		_ = tx.AddArgument(expected)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			true,
		)
	})
}

func TestBPMiningOneRound(t *testing.T) {
	b := newEmulator()

	btMiningInfo := BloctoTokenMiningDeployContract(b, t)

	// Add Blocto Token minter
	SetupBloctoTokenMinterForStaking(
		t, b,
		btMiningInfo.FTAddr, CadenceUFix64("10000.0"),
		btMiningInfo.BTAddr, btMiningInfo.BTSigner,
		btMiningInfo.BTMiningAddr, btMiningInfo.BTSigner)

	accountKeys := test.AccountKeyGenerator()
	user1AccountKey, user1Signer := accountKeys.NewWithSigner()
	user1Addr, err := b.CreateAccount(
		[]*flow.AccountKey{user1AccountKey},
		nil,
	)
	assert.NoError(t, err)
	// Add Blocto Pass
	MintNewBloctoPass(t, b, btMiningInfo.NFTAddr, user1Addr, user1Signer, btMiningInfo.BPAddr, btMiningInfo.BPSigner)
	BloctoTokenMiningSetupMiningReward(t, b, btMiningInfo, user1Addr, user1Signer)

	user2AccountKey, user2Signer := accountKeys.NewWithSigner()
	user2Addr, err := b.CreateAccount(
		[]*flow.AccountKey{user2AccountKey},
		nil,
	)
	assert.NoError(t, err)
	// Add Blocto Pass
	MintNewBloctoPass(t, b, btMiningInfo.NFTAddr, user2Addr, user2Signer, btMiningInfo.BPAddr, btMiningInfo.BPSigner)
	// TODO: user2 has BloctoPass on VIP tier 1
	BloctoTokenMiningSetupMiningReward(t, b, btMiningInfo, user2Addr, user2Signer)

	var user1AddrBytes, user2AddrBytes [8]byte
	copy(user1AddrBytes[:], user1Addr.Bytes())
	copy(user2AddrBytes[:], user2Addr.Bytes())

	t.Run("Should be able to add default criteria correctly", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningAddDefaultCriteriaTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		criteras := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCriterasPath, btMiningInfo.BTMiningAddr), nil)

		expected := make(map[interface{}]interface{})
		expected["tx"] = []interface{}{
			uint64(100000000),
			uint64(200000000),
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
			SetScript(btMiningGoNextRoundTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BTMiningAddr), nil)
		miningStateExpected := []cadence.Value{cadence.NewUInt8(1)} // collecting
		assert.Equal(t, miningStateExpected, miningState.(cadence.Enum).Fields)

		currentRound := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentRoundPath, btMiningInfo.BTMiningAddr), nil)
		currentRoundExpected := cadence.NewUInt64(1)
		assert.Equal(t, currentRoundExpected, currentRound)

		currentTotalReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentTotalRewardPath, btMiningInfo.BTMiningAddr), nil)
		currentTotalRewardExpected, err := cadence.NewUFix64("0.0")
		assert.NoError(t, err)
		assert.Equal(t, currentTotalRewardExpected, currentTotalReward)
	})

	t.Run("Should be able to collect data", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningCollectDataTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		_ = tx.AddArgument(cadence.NewAddress(user1Addr))
		_ = tx.AddArgument(CadenceUFix64("2.0"))
		_ = tx.AddArgument(CadenceUFix64("2.0"))
		_ = tx.AddArgument(CadenceUFix64("300.0"))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		currentTotalReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentTotalRewardPath, btMiningInfo.BTMiningAddr), nil)
		currentTotalRewardExpected, err := cadence.NewUFix64("14.0")
		assert.NoError(t, err)
		assert.Equal(t, currentTotalRewardExpected, currentTotalReward)

		usersReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetUserRewardsPath, btMiningInfo.BTMiningAddr), nil)
		usersRewardExpected := make(map[interface{}]interface{})
		user1Addr.Bytes()
		usersRewardExpected[user1AddrBytes] = uint64(1400000000)
		assert.Equal(t, usersRewardExpected, usersReward.ToGoValue())

		userRewardsCollected := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetUserRewardsCollectedPath, btMiningInfo.BTMiningAddr), nil)
		userRewardsCollectedExpected := make(map[interface{}]interface{})
		userRewardsCollectedExpected[user1AddrBytes] = uint64(1)
		assert.Equal(t, userRewardsCollectedExpected, userRewardsCollected.ToGoValue())
	})

	t.Run("Should be able to collect data instead of old data", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningCollectDataTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		_ = tx.AddArgument(cadence.NewAddress(user1Addr))
		_ = tx.AddArgument(CadenceUFix64("4.0"))
		_ = tx.AddArgument(CadenceUFix64("3.0"))
		_ = tx.AddArgument(CadenceUFix64("500.0"))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		currentTotalReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentTotalRewardPath, btMiningInfo.BTMiningAddr), nil)
		currentTotalRewardExpected, err := cadence.NewUFix64("22.0")
		assert.NoError(t, err)
		assert.Equal(t, currentTotalRewardExpected, currentTotalReward)

		usersReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetUserRewardsPath, btMiningInfo.BTMiningAddr), nil)
		usersRewardExpected := make(map[interface{}]interface{})
		user1Addr.Bytes()
		usersRewardExpected[user1AddrBytes] = uint64(2200000000)
		assert.Equal(t, usersRewardExpected, usersReward.ToGoValue())

		userRewardsCollected := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetUserRewardsCollectedPath, btMiningInfo.BTMiningAddr), nil)
		userRewardsCollectedExpected := make(map[interface{}]interface{})
		userRewardsCollectedExpected[user1AddrBytes] = uint64(1)
		assert.Equal(t, userRewardsCollectedExpected, userRewardsCollected.ToGoValue())
	})

	t.Run("Should be able to collect data with VIP-tier Blocto Pass", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningCollectDataTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		_ = tx.AddArgument(cadence.NewAddress(user2Addr))
		_ = tx.AddArgument(CadenceUFix64("4.0"))
		_ = tx.AddArgument(CadenceUFix64("15.0"))
		_ = tx.AddArgument(CadenceUFix64("50.0"))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		currentTotalReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentTotalRewardPath, btMiningInfo.BTMiningAddr), nil)
		currentTotalRewardExpected, err := cadence.NewUFix64("54.0")
		assert.NoError(t, err)
		assert.Equal(t, currentTotalRewardExpected, currentTotalReward)

		usersReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetUserRewardsPath, btMiningInfo.BTMiningAddr), nil)
		usersRewardExpected := make(map[interface{}]interface{})
		usersRewardExpected[user1AddrBytes] = uint64(2200000000)
		usersRewardExpected[user2AddrBytes] = uint64(3200000000)
		assert.Equal(t, usersRewardExpected, usersReward.ToGoValue())

		userRewardsCollected := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetUserRewardsCollectedPath, btMiningInfo.BTMiningAddr), nil)
		userRewardsCollectedExpected := make(map[interface{}]interface{})
		userRewardsCollectedExpected[user1AddrBytes] = uint64(1)
		userRewardsCollectedExpected[user2AddrBytes] = uint64(1)
		assert.Equal(t, userRewardsCollectedExpected, userRewardsCollected.ToGoValue())
	})

	t.Run("Should be able to stop collecting correctly", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningStopCollectingTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BTMiningAddr), nil)
		expected := []cadence.Value{cadence.NewUInt8(2)} // collected
		assert.Equal(t, expected, miningState.(cadence.Enum).Fields)
	})

	t.Run("Should be able to distribute rewards correctly", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningDistributeRewardTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(150).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		_ = tx.AddArgument(cadence.NewAddress(user1Addr))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		reward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningRewardPath, btMiningInfo.BTMiningAddr),
			[][]byte{json.MustEncode(cadence.Address(user1Addr))})
		rewardExpected := []interface{}{
			[]interface{}{
				uint64(1),
				uint64(1),
				CadenceUFix64("11.0").ToGoValue(),
			},
			[]interface{}{
				uint64(1),
				uint64(5),
				CadenceUFix64("11.0").ToGoValue(),
			},
		}
		assert.Equal(t, rewardExpected, reward.ToGoValue())

		rewardDistributed := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetRewardsDistributedPath, btMiningInfo.BTMiningAddr), nil)
		rewardDistributedExpected := make(map[interface{}]interface{})
		rewardDistributedExpected[user1AddrBytes] = uint64(1)
		assert.Equal(t, rewardDistributedExpected, rewardDistributed.ToGoValue())
	})

	t.Run("Should be able to prevent distributing reward repeatedly", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningDistributeRewardTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(150).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		_ = tx.AddArgument(cadence.NewAddress(user1Addr))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			true,
		)
	})

	t.Run("Should be able to distribute rewards correctly for user 2", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningDistributeRewardTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(150).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		_ = tx.AddArgument(cadence.NewAddress(user2Addr))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		reward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningRewardPath, btMiningInfo.BTMiningAddr),
			[][]byte{json.MustEncode(cadence.Address(user2Addr))})
		rewardExpected := []interface{}{
			[]interface{}{
				uint64(1),
				uint64(1),
				CadenceUFix64("16.0").ToGoValue(),
			},
			[]interface{}{
				uint64(1),
				uint64(5),
				CadenceUFix64("16.0").ToGoValue(),
			},
		}
		assert.Equal(t, rewardExpected, reward.ToGoValue())

		rewardDistributed := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetRewardsDistributedPath, btMiningInfo.BTMiningAddr), nil)
		rewardDistributedExpected := make(map[interface{}]interface{})
		rewardDistributedExpected[user1AddrBytes] = uint64(1)
		rewardDistributedExpected[user2AddrBytes] = uint64(1)
		assert.Equal(t, rewardDistributedExpected, rewardDistributed.ToGoValue())
	})

	t.Run("Should be able to finish distributing correctly", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningFinishDistributingTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BTMiningAddr), nil)
		expected := []cadence.Value{cadence.NewUInt8(3)} // distributed
		assert.Equal(t, expected, miningState.(cadence.Enum).Fields)
	})

	t.Run("Should have Collecting state after going next round", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningGoNextRoundTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BTMiningAddr), nil)
		miningStateExpected := []cadence.Value{cadence.NewUInt8(1)} // collecting
		assert.Equal(t, miningStateExpected, miningState.(cadence.Enum).Fields)

		currentRound := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentRoundPath, btMiningInfo.BTMiningAddr), nil)
		currentRoundExpected := cadence.NewUInt64(2)
		assert.Equal(t, currentRoundExpected, currentRound.(cadence.UInt64))
	})
}

func TestBPMiningOneRoundOverRewardCap(t *testing.T) {
	b := newEmulator()

	btMiningInfo := BloctoTokenMiningDeployContract(b, t)

	// Add Blocto Token minter
	SetupBloctoTokenMinterForStaking(
		t, b,
		btMiningInfo.FTAddr, CadenceUFix64("10000.0"),
		btMiningInfo.BTAddr, btMiningInfo.BTSigner,
		btMiningInfo.BTMiningAddr, btMiningInfo.BTSigner)

	accountKeys := test.AccountKeyGenerator()
	user1AccountKey, user1Signer := accountKeys.NewWithSigner()
	user1Addr, err := b.CreateAccount(
		[]*flow.AccountKey{user1AccountKey},
		nil,
	)
	assert.NoError(t, err)
	// Add Blocto Pass
	MintNewBloctoPass(t, b, btMiningInfo.NFTAddr, user1Addr, user1Signer, btMiningInfo.BPAddr, btMiningInfo.BPSigner)
	BloctoTokenMiningSetupMiningReward(t, b, btMiningInfo, user1Addr, user1Signer)

	user2AccountKey, user2Signer := accountKeys.NewWithSigner()
	user2Addr, err := b.CreateAccount(
		[]*flow.AccountKey{user2AccountKey},
		nil,
	)
	assert.NoError(t, err)
	// Add Blocto Pass
	MintNewBloctoPass(t, b, btMiningInfo.NFTAddr, user2Addr, user2Signer, btMiningInfo.BPAddr, btMiningInfo.BPSigner)
	// TODO: user2 has BloctoPass on VIP tier 1
	BloctoTokenMiningSetupMiningReward(t, b, btMiningInfo, user2Addr, user2Signer)

	var user1AddrBytes, user2AddrBytes [8]byte
	copy(user1AddrBytes[:], user1Addr.Bytes())
	copy(user2AddrBytes[:], user2Addr.Bytes())

	t.Run("Should be able to add default criteria correctly", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningAddDefaultCriteriaTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		criteras := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCriterasPath, btMiningInfo.BTMiningAddr), nil)

		expected := make(map[interface{}]interface{})
		expected["tx"] = []interface{}{
			uint64(100000000),
			uint64(200000000),
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
			SetScript(btMiningUpdateRewardCapTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		rewardCap, err := cadence.NewUFix64("10.1231")
		assert.NoError(t, err)
		_ = tx.AddArgument(rewardCap)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		newRewardCap := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetRewardCapPath, btMiningInfo.BTMiningAddr), nil)
		assert.Equal(t, rewardCap, newRewardCap)
	})

	t.Run("Should be able to go first round", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningGoNextRoundTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BTMiningAddr), nil)
		miningStateExpected := []cadence.Value{cadence.NewUInt8(1)} // collecting
		assert.Equal(t, miningStateExpected, miningState.(cadence.Enum).Fields)

		currentRound := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentRoundPath, btMiningInfo.BTMiningAddr), nil)
		currentRoundExpected := cadence.NewUInt64(1)
		assert.Equal(t, currentRoundExpected, currentRound)

		currentTotalReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentTotalRewardPath, btMiningInfo.BTMiningAddr), nil)
		currentTotalRewardExpected, err := cadence.NewUFix64("0.0")
		assert.NoError(t, err)
		assert.Equal(t, currentTotalRewardExpected, currentTotalReward)
	})

	t.Run("Should be able to collect data", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningCollectDataTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		_ = tx.AddArgument(cadence.NewAddress(user1Addr))
		_ = tx.AddArgument(CadenceUFix64("4.0"))
		_ = tx.AddArgument(CadenceUFix64("3.0"))
		_ = tx.AddArgument(CadenceUFix64("500.0"))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		currentTotalReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentTotalRewardPath, btMiningInfo.BTMiningAddr), nil)
		currentTotalRewardExpected, err := cadence.NewUFix64("22.0")
		assert.NoError(t, err)
		assert.Equal(t, currentTotalRewardExpected, currentTotalReward)

		usersReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetUserRewardsPath, btMiningInfo.BTMiningAddr), nil)
		usersRewardExpected := make(map[interface{}]interface{})
		user1Addr.Bytes()
		usersRewardExpected[user1AddrBytes] = uint64(2200000000)
		assert.Equal(t, usersRewardExpected, usersReward.ToGoValue())

		userRewardsCollected := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetUserRewardsCollectedPath, btMiningInfo.BTMiningAddr), nil)
		userRewardsCollectedExpected := make(map[interface{}]interface{})
		userRewardsCollectedExpected[user1AddrBytes] = uint64(1)
		assert.Equal(t, userRewardsCollectedExpected, userRewardsCollected.ToGoValue())
	})

	t.Run("Should be able to collect data with VIP-tier Blocto Pass", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningCollectDataTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		_ = tx.AddArgument(cadence.NewAddress(user2Addr))
		_ = tx.AddArgument(CadenceUFix64("5.0"))
		_ = tx.AddArgument(CadenceUFix64("15.0"))
		_ = tx.AddArgument(CadenceUFix64("50.0"))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		currentTotalReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentTotalRewardPath, btMiningInfo.BTMiningAddr), nil)
		currentTotalRewardExpected, err := cadence.NewUFix64("54.0")
		assert.NoError(t, err)
		assert.Equal(t, currentTotalRewardExpected, currentTotalReward)

		usersReward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetUserRewardsPath, btMiningInfo.BTMiningAddr), nil)
		usersRewardExpected := make(map[interface{}]interface{})
		usersRewardExpected[user1AddrBytes] = uint64(2200000000)
		usersRewardExpected[user2AddrBytes] = uint64(3200000000)
		assert.Equal(t, usersRewardExpected, usersReward.ToGoValue())

		userRewardsCollected := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetUserRewardsCollectedPath, btMiningInfo.BTMiningAddr), nil)
		userRewardsCollectedExpected := make(map[interface{}]interface{})
		userRewardsCollectedExpected[user1AddrBytes] = uint64(1)
		userRewardsCollectedExpected[user2AddrBytes] = uint64(1)
		assert.Equal(t, userRewardsCollectedExpected, userRewardsCollected.ToGoValue())
	})

	t.Run("Should be able to stop collecting correctly", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningStopCollectingTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BTMiningAddr), nil)
		expected := []cadence.Value{cadence.NewUInt8(2)} // collected
		assert.Equal(t, expected, miningState.(cadence.Enum).Fields)
	})

	t.Run("Should be able to distribute rewards correctly for user 1", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningDistributeRewardTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(150).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		_ = tx.AddArgument(cadence.NewAddress(user1Addr))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		reward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningRewardPath, btMiningInfo.BTMiningAddr),
			[][]byte{json.MustEncode(cadence.Address(user1Addr))})
		rewardExpected := []interface{}{
			[]interface{}{
				uint64(1),
				uint64(1),
				CadenceUFix64("2.06211296").ToGoValue(),
			},
			[]interface{}{
				uint64(1),
				uint64(5),
				CadenceUFix64("2.06211296").ToGoValue(),
			},
		}
		assert.Equal(t, rewardExpected, reward.ToGoValue())

		rewardDistributed := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetRewardsDistributedPath, btMiningInfo.BTMiningAddr), nil)
		rewardDistributedExpected := make(map[interface{}]interface{})
		rewardDistributedExpected[user1AddrBytes] = uint64(1)
		assert.Equal(t, rewardDistributedExpected, rewardDistributed.ToGoValue())
	})

	t.Run("Should be able to distribute rewards correctly for user 2", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningDistributeRewardTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(150).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		_ = tx.AddArgument(cadence.NewAddress(user2Addr))

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		reward := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningRewardPath, btMiningInfo.BTMiningAddr),
			[][]byte{json.MustEncode(cadence.Address(user2Addr))})
		rewardExpected := []interface{}{
			[]interface{}{
				uint64(1),
				uint64(1),
				CadenceUFix64("2.99943704").ToGoValue(),
			},
			[]interface{}{
				uint64(1),
				uint64(5),
				CadenceUFix64("2.99943703").ToGoValue(),
			},
		}
		assert.Equal(t, rewardExpected, reward.ToGoValue())

		rewardDistributed := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetRewardsDistributedPath, btMiningInfo.BTMiningAddr), nil)
		rewardDistributedExpected := make(map[interface{}]interface{})
		rewardDistributedExpected[user1AddrBytes] = uint64(1)
		rewardDistributedExpected[user2AddrBytes] = uint64(1)
		assert.Equal(t, rewardDistributedExpected, rewardDistributed.ToGoValue())
	})

	t.Run("Should be able to finish distributing correctly", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningFinishDistributingTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BTMiningAddr), nil)
		expected := []cadence.Value{cadence.NewUInt8(3)} // distributed
		assert.Equal(t, expected, miningState.(cadence.Enum).Fields)
	})

	t.Run("Should have Collecting state after going next round", func(t *testing.T) {
		tx := flow.NewTransaction().
			SetScript(btMiningGoNextRoundTransaction(btMiningInfo.BTMiningAddr)).
			SetGasLimit(100).
			SetProposalKey(b.ServiceKey().Address, b.ServiceKey().Index, b.ServiceKey().SequenceNumber).
			SetPayer(b.ServiceKey().Address).
			AddAuthorizer(btMiningInfo.BTMiningAddr)

		signAndSubmit(
			t, b, tx,
			[]flow.Address{b.ServiceKey().Address, btMiningInfo.BTMiningAddr},
			[]crypto.Signer{b.ServiceKey().Signer(), btMiningInfo.BTMiningSigner},
			false,
		)

		miningState := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetMiningStatePath, btMiningInfo.BTMiningAddr), nil)
		miningStateExpected := []cadence.Value{cadence.NewUInt8(1)} // collecting
		assert.Equal(t, miningStateExpected, miningState.(cadence.Enum).Fields)

		currentRound := executeScriptAndCheck(t, b,
			btMiningGetPropertyScript(bpMiningGetCurrentRoundPath, btMiningInfo.BTMiningAddr), nil)
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

func btMiningDistributeRewardTransaction(btMiningAddr flow.Address) []byte {
	return []byte(strings.ReplaceAll(
		string(readFile(bpMiningDistributeRewardPath)),
		"\"../../contracts/flow/mining/BloctoTokenMining.cdc\"",
		"0x"+btMiningAddr.String(),
	))
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

func btMiningUpdateRewardLockPeriodTransaction(btMiningAddr flow.Address) []byte {
	return []byte(strings.ReplaceAll(
		string(readFile(bpMiningUpdateRewardLockPeriodPath)),
		"\"../../contracts/flow/mining/BloctoTokenMining.cdc\"",
		"0x"+btMiningAddr.String(),
	))
}

func btMiningUpdateRewardLockRatioTransaction(btMiningAddr flow.Address) []byte {
	return []byte(strings.ReplaceAll(
		string(readFile(bpMiningUpdateRewardLockRatioPath)),
		"\"../../contracts/flow/mining/BloctoTokenMining.cdc\"",
		"0x"+btMiningAddr.String(),
	))
}

func btMiningSetupMiningRewardTransaction(btMiningAddr flow.Address) []byte {
	return []byte(strings.ReplaceAll(
		string(readFile(bpMiningSetupMiningRewardPath)),
		"\"../../contracts/flow/mining/BloctoTokenMining.cdc\"",
		"0x"+btMiningAddr.String(),
	))
}
