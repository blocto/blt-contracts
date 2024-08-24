import Test
import "BloctoPass"
import "BloctoTokenStaking"

access(all) let admin = Test.getAccount(0x0000000000000007)
access(all) let stakingAdmin = Test.createAccount()
access(all) let staker1 = Test.createAccount() // user1
access(all) let staker2 = Test.createAccount() // user2

access(all) fun setup() {
    var err = Test.deployContract(
        name: "BloctoToken",
        path: "../contracts/flow/token/BloctoToken.cdc",
        arguments: [],
    )

    err = Test.deployContract(
        name: "BloctoTokenStaking",
        path: "../contracts/flow/staking/BloctoTokenStaking.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())

    err = Test.deployContract(
        name: "BloctoPassStamp",
        path: "../contracts/flow/token/BloctoPassStamp.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())

    err = Test.deployContract(
        name: "BloctoPass",
        path: "../contracts/flow/token/BloctoPass.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
}


access(all) fun testInitInfo() {
    // set epoch
    let setupCode = Test.readFile("../transactions/staking/setEpoch.cdc")
    let setupTx = Test.Transaction(
        code: setupCode,
        authorizers: [admin.address],
        signers: [admin],
        arguments: [0 as UInt64],
    )
    let setupTxResult = Test.executeTransaction(setupTx)
    Test.expect(setupTxResult, Test.beSucceeded())


    Test.assertEqual(0 as UInt64, BloctoTokenStaking.getEpoch())
    Test.assertEqual(0.0, BloctoTokenStaking.getTotalStaked())
    Test.assertEqual(true, BloctoTokenStaking.getStakingEnabled())
    Test.assertEqual(1.0, BloctoTokenStaking.getEpochTokenPayout())
    Test.assertEqual(0, BloctoTokenStaking.getStakerIDCount())
}

// prepare for staker1, transferAmount=10000, stakeAmount=8000
access(all) fun testSetupStakingAdmin() {
    // create BloctoToken vault for stakingAdmin
    let setupVaultCode = Test.readFile("../transactions/token/setupBloctoTokenVault.cdc")
    let setupVaultTx = Test.Transaction(
        code: setupVaultCode,
        authorizers: [stakingAdmin.address],
        signers: [stakingAdmin],
        arguments: [],
    )
    let setupVaultTxResult = Test.executeTransaction(setupVaultTx)
    Test.expect(setupVaultTxResult, Test.beSucceeded())

    // grant admin capability for stakingAdmin 
     let setupCode = Test.readFile("../transactions/staking/setupStakingAdmin.cdc")
    let setupTx = Test.Transaction(
        code: setupCode,
        authorizers: [admin.address, stakingAdmin.address ],
        signers: [admin,  stakingAdmin],
        arguments: [],
    )
    let setupTxResult = Test.executeTransaction(setupTx)
    Test.expect(setupTxResult, Test.beSucceeded())

}

// publish to /public/bloctoPassMinter
access(all) fun testSetupBloctoPassMinterPublic() {
    let setupCode = Test.readFile("../transactions/token/admin/setupBloctoPassMinterPublic.cdc")
    let setupVaultTx = Test.Transaction(
        code: setupCode,
        authorizers: [admin.address],
        signers: [admin],
        arguments: [],
    )
    let txResult = Test.executeTransaction(setupVaultTx)
    Test.expect(txResult, Test.beSucceeded())
}
// grant admin to mint BloctoToken
access(all) fun testSetupBloctoTokenMinter() {
    let setupCode = Test.readFile("../transactions/token/admin/setupBloctoTokenMinterForStakingSelf.cdc")
    let setupVaultTx = Test.Transaction(
        code: setupCode,
        authorizers: [admin.address],
        signers: [admin],
        arguments: [100000.0],
    )
    let txResult = Test.executeTransaction(setupVaultTx)
    Test.expect(txResult, Test.beSucceeded())
}

// grant stakingAdmin to mint BloctoToken
access(all) fun testSetupBloctoTokenMinterForStakingAdmin() {
    let setupCode = Test.readFile("../transactions/token/admin/setupBloctoTokenMinterForStaking.cdc")
    let setupVaultTx = Test.Transaction(
        code: setupCode,
        authorizers: [admin.address, stakingAdmin.address],
        signers: [admin, stakingAdmin],
        arguments: [100000.0],
    )
    let txResult = Test.executeTransaction(setupVaultTx)
    Test.expect(txResult, Test.beSucceeded())
}

// prepare for staker1, transferAmount=10000, stakeAmount=8000
access(all) fun testSetupStaker1() {
    // create BloctoToken vault for staker1
    let setupVaultCode = Test.readFile("../transactions/token/setupBloctoTokenVault.cdc")
    let setupVaultTx = Test.Transaction(
        code: setupVaultCode,
        authorizers: [staker1.address],
        signers: [staker1],
        arguments: [],
    )
    let setupVaultTxResult = Test.executeTransaction(setupVaultTx)
    Test.expect(setupVaultTxResult, Test.beSucceeded())

    // // create BloctoPass for staker1
    let setupBloctoPassCode = Test.readFile("../transactions/token/setupBloctoPassCollection.cdc")
    let setupBloctoPassTx = Test.Transaction(
        code: setupBloctoPassCode,
        authorizers: [staker1.address],
        signers: [staker1],
        arguments: [],
    )
    let setupBloctoPassTxResult = Test.executeTransaction(setupBloctoPassTx)
    Test.expect(setupBloctoPassTxResult, Test.beSucceeded())

    // execute transfer transaction
    let transferAmount = 10000.0
    let transferCode = Test.readFile("../transactions/token/transferBloctoToken.cdc")
    let transferTx = Test.Transaction(
        code: transferCode,
        authorizers: [admin.address],
        signers: [admin],
        arguments: [transferAmount, staker1.address],
    )
    let transferTxResult = Test.executeTransaction(transferTx)
    Test.expect(transferTxResult, Test.beSucceeded())

    let getBalanceScript = Test.readFile("../scripts/token/getBloctoTokenBalance.cdc")
    var getBalanceResult = Test.executeScript(getBalanceScript, [staker1.address])
    let staker1Balance = getBalanceResult.returnValue! as! UFix64
    Test.assertEqual(transferAmount, staker1Balance)

    // execute stake transaction
    let stakeAmount = 8000.0
    let stakeCode = Test.readFile("../transactions/staking/app/EnableBltStake.cdc")
    let stakeTx = Test.Transaction(
        code: stakeCode,
        authorizers: [staker1.address],
        signers: [staker1],
        arguments: [stakeAmount, 0, admin.address],
    )
    let stakeTxResult = Test.executeTransaction(stakeTx)
    Test.expect(stakeTxResult, Test.beSucceeded())

    // check balance
    getBalanceResult = Test.executeScript(getBalanceScript, [staker1.address])
    let newstaker1Balance = getBalanceResult.returnValue! as! UFix64
    Test.assertEqual(transferAmount - stakeAmount, newstaker1Balance)

    // check staking info
    let stakingInfoScript = Test.readFile("../scripts/staking/getStakingInfo.cdc")
    let stakingInfoResult = Test.executeScript(stakingInfoScript, [staker1.address, 0])
    let stakingInfo :BloctoTokenStaking.StakerInfo = stakingInfoResult.returnValue! as! BloctoTokenStaking.StakerInfo

    Test.assertEqual(stakeAmount, stakingInfo.tokensCommitted)
}

// prepare for staker2, transferAmount=10000, stakeAmount=2000
access(all) fun testSetupstaker2() {
    // create BloctoToken vault for staker2
    let setupVaultCode = Test.readFile("../transactions/token/setupBloctoTokenVault.cdc")
    let setupVaultTx = Test.Transaction(
        code: setupVaultCode,
        authorizers: [staker2.address],
        signers: [staker2],
        arguments: [],
    )
    let setupVaultTxResult = Test.executeTransaction(setupVaultTx)
    Test.expect(setupVaultTxResult, Test.beSucceeded())

    // // create BloctoPass for staker2
    let setupBloctoPassCode = Test.readFile("../transactions/token/setupBloctoPassCollection.cdc")
    let setupBloctoPassTx = Test.Transaction(
        code: setupBloctoPassCode,
        authorizers: [staker2.address],
        signers: [staker2],
        arguments: [],
    )
    let setupBloctoPassTxResult = Test.executeTransaction(setupBloctoPassTx)
    Test.expect(setupBloctoPassTxResult, Test.beSucceeded())

    // execute transfer transaction
    let transferAmount = 10000.0
    let transferCode = Test.readFile("../transactions/token/transferBloctoToken.cdc")
    let transferTx = Test.Transaction(
        code: transferCode,
        authorizers: [admin.address],
        signers: [admin],
        arguments: [transferAmount, staker2.address],
    )
    let transferTxResult = Test.executeTransaction(transferTx)
    Test.expect(transferTxResult, Test.beSucceeded())

    let getBalanceScript = Test.readFile("../scripts/token/getBloctoTokenBalance.cdc")
    var getBalanceResult = Test.executeScript(getBalanceScript, [staker2.address])
    let staker2Balance = getBalanceResult.returnValue! as! UFix64
    Test.assertEqual(transferAmount, staker2Balance)

    // execute stake transaction
    let stakeAmount = 2000.0
    let stakeCode = Test.readFile("../transactions/staking/app/EnableBltStake.cdc")
    let stakeTx = Test.Transaction(
        code: stakeCode,
        authorizers: [staker2.address],
        signers: [staker2],
        arguments: [stakeAmount, 0, admin.address],
    )
    let stakeTxResult = Test.executeTransaction(stakeTx)
    Test.expect(stakeTxResult, Test.beSucceeded())

    // check balance
    getBalanceResult = Test.executeScript(getBalanceScript, [staker2.address])
    let newstaker2Balance = getBalanceResult.returnValue! as! UFix64
    Test.assertEqual(transferAmount - stakeAmount, newstaker2Balance)

    // check staking info
    let stakingInfoScript = Test.readFile("../scripts/staking/getStakingInfo.cdc")
    let stakingInfoResult = Test.executeScript(stakingInfoScript, [staker2.address, 0])
    let stakingInfo :BloctoTokenStaking.StakerInfo = stakingInfoResult.returnValue! as! BloctoTokenStaking.StakerInfo
   
    Test.assertEqual(stakeAmount, stakingInfo.tokensCommitted)
}
// switch epoch to 1
access(all) fun testSwitchEpochTo1() {
    // check init epoch is 0
    let epochScript = Test.readFile("../scripts/staking/getEpoch.cdc")
    var epochResult = Test.executeScript(epochScript, [])
    let epoch :UInt64 = epochResult.returnValue! as! UInt64
    Test.assertEqual(0 as UInt64, epoch)

    // switch epoch to 1
    let stakerIDList:[UInt64] = [0, 1]    
    let setupCode = Test.readFile("../transactions/staking/switchEpoch.cdc")
    let setupTx = Test.Transaction(
        code: setupCode,
        authorizers: [stakingAdmin.address],
        signers: [stakingAdmin],
        arguments: [stakerIDList],
    )
    let setupTxResult = Test.executeTransaction(setupTx)
    Test.expect(setupTxResult, Test.beSucceeded())

    
    // check is new epoch
    let events = Test.eventsOfType(Type<BloctoTokenStaking.NewEpoch>())
    Test.assertEqual(1, events.length)
    let event0 = events[0] as! BloctoTokenStaking.NewEpoch
    Test.assertEqual(1 as UInt64, event0.epoch)
    Test.assertEqual(10000.0, event0.totalStaked)
    Test.assertEqual(1.0, event0.totalRewardPayout)

    // check staker1 staking info
    let stakingInfoScript = Test.readFile("../scripts/staking/getStakingInfo.cdc")
    var stakingInfoResult = Test.executeScript(stakingInfoScript, [staker1.address, 0])
    var stakingInfo :BloctoTokenStaking.StakerInfo = stakingInfoResult.returnValue! as! BloctoTokenStaking.StakerInfo
   
    Test.assertEqual(0.0, stakingInfo.tokensCommitted)
    Test.assertEqual(8000.0, stakingInfo.tokensStaked)
    Test.assertEqual(0.0, stakingInfo.tokensRewarded)
    Test.assertEqual(0.0, stakingInfo.tokensRequestedToUnstake)
    Test.assertEqual(0.0, stakingInfo.tokensUnstaked)


    // check staker2 staking info
    stakingInfoResult = Test.executeScript(stakingInfoScript, [staker2.address, 0])
    stakingInfo = stakingInfoResult.returnValue! as! BloctoTokenStaking.StakerInfo
   
    Test.assertEqual(0.0, stakingInfo.tokensCommitted)
    Test.assertEqual(2000.0, stakingInfo.tokensStaked)
    Test.assertEqual(0.0, stakingInfo.tokensRewarded)
    Test.assertEqual(0.0, stakingInfo.tokensRequestedToUnstake)
    Test.assertEqual(0.0, stakingInfo.tokensUnstaked)
    
}

access(all) fun testSetEpochTokenPayout() {
    let setupCode = Test.readFile("../transactions/staking/setEpochTokenPayout.cdc")
    let setupTx = Test.Transaction(
        code: setupCode,
        authorizers: [admin.address],
        signers: [admin],
        arguments: [5000.0],
    )
    let setupTxResult = Test.executeTransaction(setupTx)
    Test.expect(setupTxResult, Test.beSucceeded())
}

// switch epoch to 2
access(all) fun testSwitchEpochTo2() {
    // check init epoch is 0
    let epochScript = Test.readFile("../scripts/staking/getEpoch.cdc")
    var epochResult = Test.executeScript(epochScript, [])
    let epoch :UInt64 = epochResult.returnValue! as! UInt64
    Test.assertEqual(1 as UInt64, epoch)

    // switch epoch to 1
    let stakerIDList:[UInt64] = [0, 1]    
    let setupCode = Test.readFile("../transactions/staking/switchEpoch.cdc")
    let setupTx = Test.Transaction(
        code: setupCode,
        authorizers: [stakingAdmin.address],
        signers: [stakingAdmin],
        arguments: [stakerIDList],
    )
    let setupTxResult = Test.executeTransaction(setupTx)
    Test.expect(setupTxResult, Test.beSucceeded())

    let events: [AnyStruct] = Test.eventsOfType(Type<BloctoTokenStaking.NewEpoch>())
    Test.assertEqual(2, events.length)
    let event1 = events[1] as! BloctoTokenStaking.NewEpoch
    Test.assertEqual(2 as UInt64, event1.epoch)
    Test.assertEqual(10000.0, event1.totalStaked)
    Test.assertEqual(5000.0, event1.totalRewardPayout)

    // check staker1 staking info
    let stakingInfoScript = Test.readFile("../scripts/staking/getStakingInfo.cdc")
    var stakingInfoResult = Test.executeScript(stakingInfoScript, [staker1.address, 0])
    var stakingInfo :BloctoTokenStaking.StakerInfo = stakingInfoResult.returnValue! as! BloctoTokenStaking.StakerInfo
   
    Test.assertEqual(0.0, stakingInfo.tokensCommitted)
    Test.assertEqual(8000.0, stakingInfo.tokensStaked)
    Test.assertEqual(4000.0, stakingInfo.tokensRewarded)
    Test.assertEqual(0.0, stakingInfo.tokensRequestedToUnstake)
    Test.assertEqual(0.0, stakingInfo.tokensUnstaked)


    // check staker2 staking info
    stakingInfoResult = Test.executeScript(stakingInfoScript, [staker2.address, 0])
    stakingInfo = stakingInfoResult.returnValue! as! BloctoTokenStaking.StakerInfo
   
    Test.assertEqual(0.0, stakingInfo.tokensCommitted)
    Test.assertEqual(2000.0, stakingInfo.tokensStaked)
    Test.assertEqual(1000.0, stakingInfo.tokensRewarded)
    Test.assertEqual(0.0, stakingInfo.tokensRequestedToUnstake)
    Test.assertEqual(0.0, stakingInfo.tokensUnstaked)
}

access(all) fun testStaker1ClaimReward() {
    // before claim reward balance
    let getBalanceScript = Test.readFile("../scripts/token/getBloctoTokenBalance.cdc")
    var getBalanceResult = Test.executeScript(getBalanceScript, [staker1.address])
    let staker1Balance = getBalanceResult.returnValue! as! UFix64

    // execute stake transaction
    let claimAmount = 4000.0
    let stakeCode = Test.readFile("../transactions/staking/app/ClaimRewardBlt.cdc")
    let stakeTx = Test.Transaction(
        code: stakeCode,
        authorizers: [staker1.address],
        signers: [staker1],
        arguments: [claimAmount, 0],
    )
    let stakeTxResult = Test.executeTransaction(stakeTx)
    Test.expect(stakeTxResult, Test.beSucceeded())

    // after claim reward balance
    getBalanceResult = Test.executeScript(getBalanceScript, [staker1.address])
    let newStaker1Balance = getBalanceResult.returnValue! as! UFix64
    Test.assertEqual(staker1Balance + claimAmount, newStaker1Balance)
}

access(all) fun testStaker1StakeNewBLT() {
    // before stakingInfo
    let stakingInfoScript = Test.readFile("../scripts/staking/getStakingInfo.cdc")
    var stakingInfoResult = Test.executeScript(stakingInfoScript, [staker1.address, 0])
    var stakingInfo :BloctoTokenStaking.StakerInfo = stakingInfoResult.returnValue! as! BloctoTokenStaking.StakerInfo

    // before BLT balance
    let getBalanceScript = Test.readFile("../scripts/token/getBloctoTokenBalance.cdc")
    var getBalanceResult = Test.executeScript(getBalanceScript, [staker1.address])
    let staker1Balance = getBalanceResult.returnValue! as! UFix64

    // execute stake transaction
    let stakeAmount = 3000.0
    let stakeCode = Test.readFile("../transactions/staking/app/StakeNewBlt.cdc")
    let stakeTx = Test.Transaction(
        code: stakeCode,
        authorizers: [staker1.address],
        signers: [staker1],
        arguments: [stakeAmount, 0],
    )
    let stakeTxResult = Test.executeTransaction(stakeTx)
    Test.expect(stakeTxResult, Test.beSucceeded())

    // check balance
    getBalanceResult = Test.executeScript(getBalanceScript, [staker1.address])
    let newstaker1Balance: UFix64 = getBalanceResult.returnValue! as! UFix64
    Test.assertEqual(staker1Balance - stakeAmount, newstaker1Balance)

    // check staking info
    stakingInfoResult = Test.executeScript(stakingInfoScript, [staker1.address, 0])
    let newStakingInfo :BloctoTokenStaking.StakerInfo = stakingInfoResult.returnValue! as! BloctoTokenStaking.StakerInfo


    Test.assertEqual(stakingInfo.tokensCommitted +  stakeAmount, newStakingInfo.tokensCommitted)
}


// staker2 request to unstake all amount, stakingInfo will from  tokensStaked -> tokensRequestedToUnstake
access(all) fun testStaker2Unstake() {
    // before staker info
    let stakingInfoScript = Test.readFile("../scripts/staking/getStakingInfo.cdc")
    var stakingInfoResult = Test.executeScript(stakingInfoScript, [staker2.address, 0])
    let stakingInfo :BloctoTokenStaking.StakerInfo = stakingInfoResult.returnValue! as! BloctoTokenStaking.StakerInfo
    let unstakeAmount = stakingInfo.tokensStaked
    // request to unstake all amount
    let stakerIDList:[UInt64] = [0, 1]    
    let setupCode = Test.readFile("../transactions/staking/app/RequestToUnstakeBlt.cdc")
    let setupTx = Test.Transaction(
        code: setupCode,
        authorizers: [staker2.address],
        signers: [staker2],
        arguments: [unstakeAmount, 0],
    )
    let setupTxResult = Test.executeTransaction(setupTx)
    Test.expect(setupTxResult, Test.beSucceeded())


    stakingInfoResult = Test.executeScript(stakingInfoScript, [staker2.address, 0])
    let afterStakingInfo :BloctoTokenStaking.StakerInfo = stakingInfoResult.returnValue! as! BloctoTokenStaking.StakerInfo
    Test.assertEqual(unstakeAmount, afterStakingInfo.tokensRequestedToUnstake)
}

// switch epoch to 3, staker2 stakingInfo will from tokensRequestedToUnstake -> tokensUnstaked
access(all) fun testSwitchEpochTo3() {
    // check init epoch is 0
    let epochScript = Test.readFile("../scripts/staking/getEpoch.cdc")
    var epochResult = Test.executeScript(epochScript, [])
    let epoch :UInt64 = epochResult.returnValue! as! UInt64
    Test.assertEqual(2 as UInt64, epoch)

    // before staker2's stakinginfo
    let stakingInfoScript = Test.readFile("../scripts/staking/getStakingInfo.cdc")
    var stakingInfoResult = Test.executeScript(stakingInfoScript, [staker2.address, 0])
    let stakingInfo :BloctoTokenStaking.StakerInfo = stakingInfoResult.returnValue! as! BloctoTokenStaking.StakerInfo

    // switch epoch to next epoch
    let stakerIDList:[UInt64] = [0, 1]    
    let setupCode = Test.readFile("../transactions/staking/switchEpoch.cdc")
    let setupTx = Test.Transaction(
        code: setupCode,
        authorizers: [stakingAdmin.address],
        signers: [stakingAdmin],
        arguments: [stakerIDList],
    )
    let setupTxResult = Test.executeTransaction(setupTx)
    Test.expect(setupTxResult, Test.beSucceeded())
    // check is new epoch
    epochResult = Test.executeScript(epochScript, [])
    let newEpoch :UInt64 = epochResult.returnValue! as! UInt64
    Test.assertEqual(3 as UInt64, newEpoch)


    // check staker2 staking info
    stakingInfoResult = Test.executeScript(stakingInfoScript, [staker2.address, 0])
    let afterStakingInfo :BloctoTokenStaking.StakerInfo = stakingInfoResult.returnValue! as! BloctoTokenStaking.StakerInfo
    Test.assertEqual(afterStakingInfo.tokensUnstaked, stakingInfo.tokensRequestedToUnstake)
}

access(all) fun testStakeUnstakedBLT() {
    // before stakingInfo
    let stakingInfoScript = Test.readFile("../scripts/staking/getStakingInfo.cdc")
    var stakingInfoResult = Test.executeScript(stakingInfoScript, [staker2.address, 0])
    let stakingInfo :BloctoTokenStaking.StakerInfo = stakingInfoResult.returnValue! as! BloctoTokenStaking.StakerInfo
    
    // stake unstaked BLT
    let restakeAmount = stakingInfo.tokensUnstaked * 0.5
    let stakerIDList:[UInt64] = [0, 1]    
    let setupCode = Test.readFile("../transactions/staking/app/StakeUnstakedBlt.cdc")
    let setupTx = Test.Transaction(
        code: setupCode,
        authorizers: [staker2.address],
        signers: [staker2],
        arguments: [restakeAmount, 0],
    )
    let setupTxResult = Test.executeTransaction(setupTx)
    Test.expect(setupTxResult, Test.beSucceeded())

    // check staking info
    stakingInfoResult = Test.executeScript(stakingInfoScript, [staker2.address, 0])
    let afterStakingInfo :BloctoTokenStaking.StakerInfo = stakingInfoResult.returnValue! as! BloctoTokenStaking.StakerInfo
    Test.assertEqual(stakingInfo.tokensUnstaked - restakeAmount, afterStakingInfo.tokensUnstaked)
    Test.assertEqual(stakingInfo.tokensCommitted + restakeAmount, afterStakingInfo.tokensCommitted)
}

access(all) fun testStaker2ClaimUnstakedBLT() {
    // before stakingInfo
    let stakingInfoScript = Test.readFile("../scripts/staking/getStakingInfo.cdc")
    var stakingInfoResult = Test.executeScript(stakingInfoScript, [staker2.address, 0])
    let stakingInfo :BloctoTokenStaking.StakerInfo = stakingInfoResult.returnValue! as! BloctoTokenStaking.StakerInfo
    
    // before claim unstaked BLT balance
    let getBalanceScript = Test.readFile("../scripts/token/getBloctoTokenBalance.cdc")
    var getBalanceResult = Test.executeScript(getBalanceScript, [staker2.address])
    let balance = getBalanceResult.returnValue! as! UFix64

    // execute claim unstake transaction
    let stakeCode = Test.readFile("../transactions/staking/app/ClaimUnstakedBlt.cdc")
    let stakeTx = Test.Transaction(
        code: stakeCode,
        authorizers: [staker2.address],
        signers: [staker2],
        arguments: [stakingInfo.tokensUnstaked, 0],
    )
    let stakeTxResult = Test.executeTransaction(stakeTx)
    Test.expect(stakeTxResult, Test.beSucceeded())

    // after claim reward balance
    getBalanceResult = Test.executeScript(getBalanceScript, [staker2.address])
    let newBalance = getBalanceResult.returnValue! as! UFix64
    Test.assertEqual(balance + stakingInfo.tokensUnstaked, newBalance)
}