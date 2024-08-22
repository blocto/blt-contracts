import Test
import "BloctoPass"
import "BloctoTokenStaking"

access(all) let admin = Test.getAccount(0x0000000000000007)
access(all) let staker = Test.createAccount()
access(all) let minter = Test.createAccount()

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
access(all) fun testSetupForStaker() {
    // create BloctoToken vault for staker
    let setupVaultCode = Test.readFile("../transactions/token/setupBloctoTokenVault.cdc")
    let setupVaultTx = Test.Transaction(
        code: setupVaultCode,
        authorizers: [staker.address],
        signers: [staker],
        arguments: [],
    )
    let setupVaultTxResult = Test.executeTransaction(setupVaultTx)
    Test.expect(setupVaultTxResult, Test.beSucceeded())

    // // create BloctoPass for staker
    let setupBloctoPassCode = Test.readFile("../transactions/token/setupBloctoPassCollection.cdc")
    let setupBloctoPassTx = Test.Transaction(
        code: setupBloctoPassCode,
        authorizers: [staker.address],
        signers: [staker],
        arguments: [],
    )
    let setupBloctoPassTxResult = Test.executeTransaction(setupBloctoPassTx)
    Test.expect(setupBloctoPassTxResult, Test.beSucceeded())
}


access(all) fun testStake() {
    // execute transfer transaction
    let transferAmount = 10000.0
    let transferCode = Test.readFile("../transactions/token/transferBloctoToken.cdc")
    let transferTx = Test.Transaction(
        code: transferCode,
        authorizers: [admin.address],
        signers: [admin],
        arguments: [transferAmount, staker.address],
    )
    let transferTxResult = Test.executeTransaction(transferTx)
    Test.expect(transferTxResult, Test.beSucceeded())

    let getBalanceScript = Test.readFile("../scripts/token/getBloctoTokenBalance.cdc")
    var getBalanceResult = Test.executeScript(getBalanceScript, [staker.address])
    let stakerBalance = getBalanceResult.returnValue! as! UFix64
    Test.assertEqual(transferAmount, stakerBalance)

    // execute stake transaction
    let stakeAmount = 8000.0
    let stakeCode = Test.readFile("../transactions/staking/EnableBltStake.cdc")
    let stakeTx = Test.Transaction(
        code: stakeCode,
        authorizers: [staker.address],
        signers: [staker],
        arguments: [stakeAmount, 0, admin.address],
    )
    let stakeTxResult = Test.executeTransaction(stakeTx)
    Test.expect(stakeTxResult, Test.beSucceeded())

    // check balance
    getBalanceResult = Test.executeScript(getBalanceScript, [staker.address])
    let newStakerBalance = getBalanceResult.returnValue! as! UFix64
    Test.assertEqual(transferAmount - stakeAmount, newStakerBalance)

    // check staking info
    let stakingInfoScript = Test.readFile("../scripts/staking/getStakingInfo.cdc")
    let stakingInfoResult = Test.executeScript(stakingInfoScript, [staker.address, 0])
    let stakingInfo :BloctoTokenStaking.StakerInfo = stakingInfoResult.returnValue! as! BloctoTokenStaking.StakerInfo
   
     Test.assertEqual(stakeAmount, stakingInfo.tokensCommitted)
}
