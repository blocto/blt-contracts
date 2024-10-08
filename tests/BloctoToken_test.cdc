import Test
import "BloctoToken"

access(all) let admin = Test.getAccount(0x0000000000000007)
access(all) let receiver = Test.createAccount()
access(all) let receiver2 = Test.createAccount()
access(all) let minter = Test.createAccount()

access(all) fun setup() {
    let err = Test.deployContract(
        name: "BloctoToken",
        path: "../contracts/flow/token/BloctoToken.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
}

access(all) fun testTotalSupply() {
    // get total supply
    let getTotalSupplyScript = Test.readFile("../scripts/token/getTotalSupply.cdc")
    let result = Test.executeScript(getTotalSupplyScript, [])
    let totalSupply = result.returnValue! as! UFix64
    Test.assertEqual(350_000_000.0, totalSupply)
}

access(all) fun testSetupVault() {
    // create vault for receiver
    let setupVaultCode = Test.readFile("../transactions/token/setupBloctoTokenVault.cdc")
    let setupVaultTx = Test.Transaction(
        code: setupVaultCode,
        authorizers: [receiver.address],
        signers: [receiver],
        arguments: [],
    )
    let setupVaultTxResult = Test.executeTransaction(setupVaultTx)
    Test.expect(setupVaultTxResult, Test.beSucceeded())

    // create vault for receiver
    let setupVaultTx2 = Test.Transaction(
        code: setupVaultCode,
        authorizers: [receiver2.address],
        signers: [receiver2],
        arguments: [],
    )
    let setupVaultTxResult2 = Test.executeTransaction(setupVaultTx2)
    Test.expect(setupVaultTxResult2, Test.beSucceeded())
}

access(all) fun testTransfer() {
    // get original balance
    let getBalanceScript = Test.readFile("../scripts/token/getBloctoTokenBalance.cdc")
    var  getBalanceResult = Test.executeScript(getBalanceScript, [admin.address])
    let currentSenderBalance = getBalanceResult.returnValue! as! UFix64
    getBalanceResult = Test.executeScript(getBalanceScript, [receiver.address])
    let currentReceiverBalance = getBalanceResult.returnValue! as! UFix64
  
    // execute transfer transaction
    let transferAmount = 10.0
    let transferCode = Test.readFile("../transactions/token/transferBloctoToken.cdc")
    let transferTx = Test.Transaction(
        code: transferCode,
        authorizers: [admin.address],
        signers: [admin],
        arguments: [transferAmount, receiver.address],
    )
    let transferTxResult = Test.executeTransaction(transferTx)
    Test.expect(transferTxResult, Test.beSucceeded())

    // check balance result
    getBalanceResult = Test.executeScript(getBalanceScript, [admin.address])
    let senderBalance = getBalanceResult.returnValue! as! UFix64
    getBalanceResult = Test.executeScript(getBalanceScript, [receiver.address])
    let receiverBalance = getBalanceResult.returnValue! as! UFix64
    Test.assertEqual(currentSenderBalance - transferAmount, senderBalance)
    Test.assertEqual(currentReceiverBalance + transferAmount, receiverBalance)
}

access(all) fun testSetupMinter() {
    // create permission for minter
    let setupMinterCode = Test.readFile("../transactions/token/admin/setupBloctoTokenMinterForMining.cdc")
    let setupTx = Test.Transaction(
        code: setupMinterCode,
        authorizers: [admin.address, minter.address],
        signers: [admin, minter],
        arguments: [10000.0],
    )
    let setupTxResult = Test.executeTransaction(setupTx)
    Test.expect(setupTxResult, Test.beSucceeded())
}

access(all) fun testShouldNotTransferExceedAmount() {
    // get original balance
    let getBalanceScript = Test.readFile("../scripts/token/getBloctoTokenBalance.cdc")
    var getBalanceResult = Test.executeScript(getBalanceScript, [receiver2.address])
    let currentReceiver2Balance = getBalanceResult.returnValue! as! UFix64
  
    // execute transfer transaction
    let exceedAmount = 1000.0
    let transferCode = Test.readFile("../transactions/token/transferBloctoToken.cdc")
    let transferTx = Test.Transaction(
        code: transferCode,
        authorizers: [receiver.address],
        signers: [receiver],
        arguments: [exceedAmount, receiver2.address],
    )
    let transferTxResult: Test.TransactionResult = Test.executeTransaction(transferTx)
    Test.expect(transferTxResult, Test.beFailed())
   
    getBalanceResult = Test.executeScript(getBalanceScript, [receiver2.address])
    let afterReceiver2Balance = getBalanceResult.returnValue! as! UFix64
    Test.assertEqual(currentReceiver2Balance, afterReceiver2Balance)
}

access(all) fun testShouldNotTransferIfNotOwner() {
    // get original balance
    let getBalanceScript = Test.readFile("../scripts/token/getBloctoTokenBalance.cdc")
    var getBalanceResult = Test.executeScript(getBalanceScript, [receiver2.address])
    let currentReceiver2Balance = getBalanceResult.returnValue! as! UFix64
  
    // execute transfer transaction
    let amount = 1.0
    let transferCode = Test.readFile("../transactions/token/transferBloctoToken.cdc")
    let transferTx = Test.Transaction(
        code: transferCode,
        authorizers: [receiver.address],
        signers: [receiver2],
        arguments: [amount, admin.address],
    )
    let transferTxResult: Test.TransactionResult = Test.executeTransaction(transferTx)
    Test.expect(transferTxResult, Test.beFailed())
  
}

// grant stakingAdmin to mint BloctoToken
access(all) fun testShouldNotSetupBloctoTokenMinterIfNotAdmin() {
    let setupCode = Test.readFile("../transactions/token/admin/setupBloctoTokenMinterForStaking.cdc")
    let setupVaultTx = Test.Transaction(
        code: setupCode,
        authorizers: [receiver.address, receiver2.address],
        signers: [receiver, receiver2],
        arguments: [100000.0],
    )
    let txResult: Test.TransactionResult = Test.executeTransaction(setupVaultTx)
    Test.expect(txResult, Test.beFailed())
}