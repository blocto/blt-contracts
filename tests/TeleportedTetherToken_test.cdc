import Test

access(all) let admin = Test.getAccount(0x0000000000000007)
access(all) let teleportAdmin = Test.createAccount()
access(all) let receiver = Test.createAccount()
access(all) let feeReceiver = Test.createAccount()

access(all) fun setup() {
    let err = Test.deployContract(
        name: "TeleportedTetherToken",
        path: "../contracts/flow/token/TeleportedTetherToken.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
}

access(all) fun testTeleportInAndOut() {
    let setupTeleportAdminCode = Test.readFile("../transactions/token/TeleportedTetherToken/setupTeleportAdmin.cdc")
    let setupTeleportAdminTx = Test.Transaction(
        code: setupTeleportAdminCode,
        authorizers: [admin.address, teleportAdmin.address],
        signers: [admin, teleportAdmin],
        arguments: [1000.0],
    )
    let setupTeleportAdminTxResult = Test.executeTransaction(setupTeleportAdminTx)
    Test.expect(setupTeleportAdminTxResult, Test.beSucceeded())

    let setupVaultCode = Test.readFile("../transactions/token/TeleportedTetherToken/setupTokenVault.cdc")
    let setupVaultTx = Test.Transaction(
        code: setupVaultCode,
        authorizers: [receiver.address],
        signers: [receiver],
        arguments: [],
    )
    let setupVaultTxResult = Test.executeTransaction(setupVaultTx)
    Test.expect(setupVaultTxResult, Test.beSucceeded())

    let getFeesScript = Test.readFile("../scripts/token/TeleportedTetherToken/getFees.cdc")
    let getFeesResult = Test.executeScript(getFeesScript, [teleportAdmin.address])
    let fees = getFeesResult.returnValue as! {String: UFix64}?
    let inwardFee = fees!["inwardFee"]!
    let outwardFee = fees!["outwardFee"]!

    let inAmount = 10.0
    let teleportInCode = Test.readFile("../transactions/token/TeleportedTetherToken/teleportIn.cdc")
    let teleportInTx = Test.Transaction(
        code: teleportInCode,
        authorizers: [teleportAdmin.address],
        signers: [teleportAdmin],
        arguments: [
            10.0,
            receiver.address,
            "436f795B64E23E6cE7792af4923A68AFD3967952",
            "76dc89607b262938ce3a819dd8308d2909e000ac67d549b054f63b9912b5ee75"
        ],
    )
    let teleportInTxResult = Test.executeTransaction(teleportInTx)
    Test.expect(teleportInTxResult, Test.beSucceeded())

    let getTotalSupplyScript = Test.readFile("../scripts/token/TeleportedTetherToken/getTotalSupply.cdc")
    var getTotalSupplyResult = Test.executeScript(getTotalSupplyScript, [])
    Test.assertEqual(inAmount, getTotalSupplyResult.returnValue!)

    let getBalanceScript = Test.readFile("../scripts/token/TeleportedTetherToken/getBalance.cdc")
    var getBalanceResult = Test.executeScript(getBalanceScript, [receiver.address])
    Test.assertEqual(inAmount - inwardFee, getBalanceResult.returnValue!)

    let outAmount = 5.0
    let teleportOutCode = Test.readFile("../transactions/token/TeleportedTetherToken/teleportOut.cdc")
    let teleportOutTx = Test.Transaction(
        code: teleportOutCode,
        authorizers: [receiver.address],
        signers: [receiver],
        arguments: [
            teleportAdmin.address,
            outAmount,
            "436f795B64E23E6cE7792af4923A68AFD3967952"
        ]
    )
    let teleportOutTxResult = Test.executeTransaction(teleportOutTx)
    Test.expect(teleportOutTxResult, Test.beSucceeded())

    getTotalSupplyResult = Test.executeScript(getTotalSupplyScript, [])
    Test.assertEqual(inAmount - (outAmount - outwardFee), getTotalSupplyResult.returnValue!)

    getBalanceResult = Test.executeScript(getBalanceScript, [receiver.address])
    Test.assertEqual(inAmount - inwardFee - outAmount, getBalanceResult.returnValue!)
}

access(all) fun testWithdrawFee() {
    let getFeesScript = Test.readFile("../scripts/token/TeleportedTetherToken/getFees.cdc")
    let getFeesResult = Test.executeScript(getFeesScript, [teleportAdmin.address])
    let fees = getFeesResult.returnValue as! {String: UFix64}?
    let inwardFee = fees!["inwardFee"]!
    let outwardFee = fees!["outwardFee"]!

    let setupVaultCode = Test.readFile("../transactions/token/TeleportedTetherToken/setupTokenVault.cdc")
    let setupVaultTx = Test.Transaction(
        code: setupVaultCode,
        authorizers: [feeReceiver.address],
        signers: [feeReceiver],
        arguments: [],
    )
    let setupVaultTxResult = Test.executeTransaction(setupVaultTx)
    Test.expect(setupVaultTxResult, Test.beSucceeded())

    let withdrawFeeCode = Test.readFile("../transactions/token/TeleportedTetherToken/withdrawFee.cdc")
    let withdrawFeeTx = Test.Transaction(
        code: withdrawFeeCode,
        authorizers: [teleportAdmin.address],
        signers: [teleportAdmin],
        arguments: [feeReceiver.address],
    )
    let withdrawFeeTxResult = Test.executeTransaction(withdrawFeeTx)
    Test.expect(withdrawFeeTxResult, Test.beSucceeded())

    let getBalanceScript = Test.readFile("../scripts/token/TeleportedTetherToken/getBalance.cdc")
    let getBalanceResult = Test.executeScript(getBalanceScript, [feeReceiver.address])
    Test.assertEqual(inwardFee + outwardFee, getBalanceResult.returnValue!)
}

access(all) fun testFreezeAndUnfreeze() {
    let getIsFrozenScript = Test.readFile("../scripts/token/TeleportedTetherToken/getIsFrozen.cdc")
    var getIsFrozenResult = Test.executeScript(getIsFrozenScript, [])
    Test.assertEqual(false, getIsFrozenResult.returnValue!)

    let setupFreezeCode = Test.readFile("../transactions/token/TeleportedTetherToken/setupFreeze.cdc")
    let setupFreezeTx = Test.Transaction(
        code: setupFreezeCode,
        authorizers: [admin.address],
        signers: [admin],
        arguments: [true],
    )
    let setupFreezeTxResult = Test.executeTransaction(setupFreezeTx)
    Test.expect(setupFreezeTxResult, Test.beSucceeded())

    getIsFrozenResult = Test.executeScript(getIsFrozenScript, [])
    Test.assertEqual(true, getIsFrozenResult.returnValue!)

    let inAmount = 10.0
    let teleportInCode = Test.readFile("../transactions/token/TeleportedTetherToken/teleportIn.cdc")
    let teleportInTx = Test.Transaction(
        code: teleportInCode,
        authorizers: [teleportAdmin.address],
        signers: [teleportAdmin],
        arguments: [
            10.0,
            receiver.address,
            "436f795B64E23E6cE7792af4923A68AFD3967953",
            "76dc89607b262938ce3a819dd8308d2909e000ac67d549b054f63b9912b5ee76"
        ],
    )
    var teleportInTxResult = Test.executeTransaction(teleportInTx)
    Test.expect(teleportInTxResult, Test.beFailed())

    let setupUnfreezeTx = Test.Transaction(
        code: setupFreezeCode,
        authorizers: [admin.address],
        signers: [admin],
        arguments: [false],
    )
    let setupUnfreezeTxResult = Test.executeTransaction(setupUnfreezeTx)
    Test.expect(setupUnfreezeTxResult, Test.beSucceeded())

    getIsFrozenResult = Test.executeScript(getIsFrozenScript, [])
    Test.assertEqual(false, getIsFrozenResult.returnValue!)

    teleportInTxResult = Test.executeTransaction(teleportInTx)
    Test.expect(teleportInTxResult, Test.beSucceeded())
}

access(all) fun testDepositAllowance() {
    let setupTeleportAdminCode = Test.readFile("../transactions/token/TeleportedTetherToken/setupTeleportAdmin.cdc")
    let setupTeleportAdminTx = Test.Transaction(
        code: setupTeleportAdminCode,
        authorizers: [admin.address, teleportAdmin.address],
        signers: [admin, teleportAdmin],
        arguments: [1000.0],
    )
    let setupTeleportAdminTxResult = Test.executeTransaction(setupTeleportAdminTx)
    Test.expect(setupTeleportAdminTxResult, Test.beSucceeded())

    let getAllowanceScript = Test.readFile("../scripts/token/TeleportedTetherToken/getAllowance.cdc")
    var getAllowanceResult = Test.executeScript(getAllowanceScript, [teleportAdmin.address])
    Test.assertEqual(1000.0, getAllowanceResult.returnValue!)

    let depositAllowanceCode = Test.readFile("../transactions/token/TeleportedTetherToken/depositAllowance.cdc")
    let depositAllowanceTx = Test.Transaction(
        code: depositAllowanceCode,
        authorizers: [admin.address],
        signers: [admin],
        arguments: [teleportAdmin.address, 500.0],
    )
    let depositAllowanceTxResult = Test.executeTransaction(depositAllowanceTx)
    Test.expect(depositAllowanceTxResult, Test.beSucceeded())

    getAllowanceResult = Test.executeScript(getAllowanceScript, [teleportAdmin.address])
    Test.assertEqual(1500.0, getAllowanceResult.returnValue!)
}

access(all) fun testUpdateFees() {
    let setupTeleportAdminCode = Test.readFile("../transactions/token/TeleportedTetherToken/setupTeleportAdmin.cdc")
    let setupTeleportAdminTx = Test.Transaction(
        code: setupTeleportAdminCode,
        authorizers: [admin.address, teleportAdmin.address],
        signers: [admin, teleportAdmin],
        arguments: [1000.0],
    )
    let setupTeleportAdminTxResult = Test.executeTransaction(setupTeleportAdminTx)
    Test.expect(setupTeleportAdminTxResult, Test.beSucceeded())

    let getFeesScript = Test.readFile("../scripts/token/TeleportedTetherToken/getFees.cdc")
    var getFeesResult = Test.executeScript(getFeesScript, [teleportAdmin.address])
    var fees = getFeesResult.returnValue as! {String: UFix64}?
    var inwardFee = fees!["inwardFee"]!
    var outwardFee = fees!["outwardFee"]!
    Test.assertEqual(0.01, inwardFee)
    Test.assertEqual(3.0, outwardFee)

    let updateFeesCode = Test.readFile("../transactions/token/TeleportedTetherToken/updateFees.cdc")
    let updateFeesTx = Test.Transaction(
        code: updateFeesCode,
        authorizers: [teleportAdmin.address],
        signers: [teleportAdmin],
        arguments: [1.0, 30.0],
    )
    let updateFeesTxResult = Test.executeTransaction(updateFeesTx)
    Test.expect(updateFeesTxResult, Test.beSucceeded())

    getFeesResult = Test.executeScript(getFeesScript, [teleportAdmin.address])
    fees = getFeesResult.returnValue as! {String: UFix64}?
    inwardFee = fees!["inwardFee"]!
    outwardFee = fees!["outwardFee"]!
    Test.assertEqual(1.0, inwardFee)
    Test.assertEqual(30.0, outwardFee)
}

access(all) fun testTransfer() {
    let getBalanceScript = Test.readFile("../scripts/token/TeleportedTetherToken/getBalance.cdc")
    var getBalanceResult = Test.executeScript(getBalanceScript, [receiver.address])
    let currentReceiverBalance = getBalanceResult.returnValue! as! UFix64
    getBalanceResult = Test.executeScript(getBalanceScript, [feeReceiver.address])
    let currentFeeReceiverBalance = getBalanceResult.returnValue! as! UFix64

    let transferAmount = 1.0
    let transferCode = Test.readFile("../transactions/token/TeleportedTetherToken/transfer.cdc")
    let transferTx = Test.Transaction(
        code: transferCode,
        authorizers: [receiver.address],
        signers: [receiver],
        arguments: [transferAmount, feeReceiver.address],
    )
    let transferTxResult = Test.executeTransaction(transferTx)
    Test.expect(transferTxResult, Test.beSucceeded())

    getBalanceResult = Test.executeScript(getBalanceScript, [receiver.address])
    let receiverBalance = getBalanceResult.returnValue! as! UFix64
    getBalanceResult = Test.executeScript(getBalanceScript, [feeReceiver.address])
    let feeReceiverBalance = getBalanceResult.returnValue! as! UFix64

    Test.assertEqual(currentReceiverBalance - transferAmount, receiverBalance)
    Test.assertEqual(currentFeeReceiverBalance + transferAmount, feeReceiverBalance)
}
