import Test
import "TeleportCustodyBSC"

access(all) let admin = Test.getAccount(0x0000000000000007)
access(all) let teleportAdmin = Test.createAccount()
access(all) let receiver = Test.createAccount()
access(all) let feeReceiver = Test.createAccount()

access(all) fun setup() {
    let err = Test.deployContract(
        name: "BloctoToken",
        path: "../contracts/flow/token/BloctoToken.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    let err2 = Test.deployContract(
        name: "TeleportCustodyBSC",
        path: "../contracts/flow/teleport/TeleportCustodyBSC.cdc",
        arguments: [],
    )
    Test.expect(err2, Test.beNil())
}

access(all) fun testCreateTeleportAdmin() {
    let createTeleportAdminCode = Test.readFile("../transactions/teleport/BSC/createTeleportAdminBSC.cdc")
    let createTeleportAdminTx = Test.Transaction(
        code: createTeleportAdminCode,
        authorizers: [admin.address, teleportAdmin.address],
        signers: [admin, teleportAdmin],
        arguments: [1000.0],
    )
    let createTeleportAdminTxResult = Test.executeTransaction(createTeleportAdminTx)
    Test.expect(createTeleportAdminTxResult, Test.beSucceeded())
}

access(all) fun testDepositAllowanceBSC() {
    let depositAllowanceBSCCode = Test.readFile("../transactions/teleport/BSC/depositAllowanceBSC.cdc")
    let depositAllowanceTx = Test.Transaction(
        code: depositAllowanceBSCCode,
        authorizers: [admin.address],
        signers: [admin],
        arguments: [teleportAdmin.address, 1000.0],
    )
    let depositAllowanceTxResult = Test.executeTransaction(depositAllowanceTx)
    Test.expect(depositAllowanceTxResult, Test.beSucceeded())
}

access(all) fun testAllowance() {
    let getAllowanceScript = Test.readFile("../scripts/teleport/BSC/getAllowanceBSC.cdc")
    let resultBefore = Test.executeScript(getAllowanceScript, [teleportAdmin.address])
    let allowanceBefore = resultBefore.returnValue! as! UFix64
    Test.assertEqual(2000.0, allowanceBefore)

    testDepositAllowanceBSC()
    let resultAfter = Test.executeScript(getAllowanceScript, [teleportAdmin.address])
    let allowanceAfter = resultAfter.returnValue! as! UFix64
    Test.assertEqual(3000.0, allowanceAfter)
}

access(all) fun testSetupBloctoTokenVault() {
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
}

access(all) fun testLockTokensBSC() {
    let to = "436f795B64E23E6cE7792af4923A68AFD3967952"
    testSetupBloctoTokenVault()
    let lockTokensBSCCode = Test.readFile("../transactions/teleport/BSC/lockTokensBSC.cdc")
    let lockTokensBSCTx = Test.Transaction(
        code: lockTokensBSCCode,
        authorizers: [receiver.address],
        signers: [receiver],
        arguments: [teleportAdmin.address, 5.0, to]
    )
    let lockTokenTxResult = Test.executeTransaction(lockTokensBSCTx)
    Test.expect(lockTokenTxResult, Test.beSucceeded())

    let lockedEvents = Test.eventsOfType(Type<TeleportCustodyBSC.Locked>())
    Test.assertEqual(1, lockedEvents.length)
    let lockedEvent = lockedEvents[0] as! TeleportCustodyBSC.Locked
    Test.assertEqual(2.0, lockedEvent.amount)
    Test.assertEqual(to.decodeHex(), lockedEvent.to)
}

access(all) fun testUnlockTokensBSC() {
    let from = "436f795B64E23E6cE7792af4923A68AFD3967952"
    let txHash = "31c76b8b0afbaa7029b3fbed7a2e51b9868254703d707ae98d130d35f4b7767d"
    let unlockTokensBSCCode = Test.readFile("../transactions/teleport/BSC/unlockTokensBSC.cdc")
    let unlockTokensBSCTx = Test.Transaction(
        code: unlockTokensBSCCode,
        authorizers: [teleportAdmin.address],
        signers: [teleportAdmin],
        arguments: [2.0, receiver.address, from, txHash]
    )
    let unlockTokenTxResult = Test.executeTransaction(unlockTokensBSCTx)
    Test.expect(unlockTokenTxResult, Test.beSucceeded())

    let unlockedEvents = Test.eventsOfType(Type<TeleportCustodyBSC.Unlocked>())
    Test.assertEqual(1, unlockedEvents.length)
    let unlockedEvent = unlockedEvents[0] as! TeleportCustodyBSC.Unlocked
    Test.assertEqual(2.0, unlockedEvent.amount)
    Test.assertEqual(from.decodeHex(), unlockedEvent.from)
    Test.assertEqual(txHash, unlockedEvent.txHash)
}

access(all) fun testTransferTeleportFeesBSC() {
    let setupVaultCode = Test.readFile("../transactions/token/setupBloctoTokenVault.cdc")
    let setupVaultTx = Test.Transaction(
        code: setupVaultCode,
        authorizers: [feeReceiver.address],
        signers: [feeReceiver],
        arguments: [],
    )
    let setupVaultTxResult = Test.executeTransaction(setupVaultTx)
    Test.expect(setupVaultTxResult, Test.beSucceeded())

    let getBloctoBalanceScript = Test.readFile("../scripts/token/getBloctoTokenBalance.cdc")
    let result = Test.executeScript(getBloctoBalanceScript, [feeReceiver.address])
    let bloctoBalance = result.returnValue! as! UFix64
    Test.assertEqual(0.0, bloctoBalance)

    let transferTeleportFeesCode = Test.readFile("../transactions/teleport/BSC/transferTeleportFeesBSC.cdc")
    let transferTeleportFeesTx = Test.Transaction(
        code: transferTeleportFeesCode,
        authorizers: [teleportAdmin.address],
        signers: [teleportAdmin],
        arguments: [feeReceiver.address]
    )
    let transferTeleportFeesTxResult = Test.executeTransaction(transferTeleportFeesTx)
    Test.expect(transferTeleportFeesTxResult, Test.beSucceeded())

    let newResult = Test.executeScript(getBloctoBalanceScript, [feeReceiver.address])
    let newBloctoBalance = newResult.returnValue! as! UFix64
    Test.assertEqual(3.01, newBloctoBalance)
}

access(all) fun testUpdateTeleportFeesBSC() {
    let teleportFeesScript = Test.readFile("../scripts/teleport/BSC/getTeleportFeesBSC.cdc")
    let result = Test.executeScript(teleportFeesScript, [teleportAdmin.address])
    let teleportFees = result.returnValue! as! [UFix64]
    let lockFee = teleportFees[0]
    let unlockFee = teleportFees[1]
    Test.assertEqual(3.0, lockFee)
    Test.assertEqual(0.01, unlockFee)

    let newLockFee = 5.0
    let newUnlockFee = 0.02
    let updateTeleportFeeCode = Test.readFile("../transactions/teleport/BSC/updateTeleportFeesBSC.cdc")
    let updateTeleportFeeTx = Test.Transaction(
        code: updateTeleportFeeCode,
        authorizers: [teleportAdmin.address],
        signers: [teleportAdmin],
        arguments: [newLockFee, newUnlockFee]
    )
    let updateTeleportFeeTxResult = Test.executeTransaction(updateTeleportFeeTx)
    Test.expect(updateTeleportFeeTxResult, Test.beSucceeded())

    let newResult = Test.executeScript(teleportFeesScript, [teleportAdmin.address])
    let newTeleportFees = newResult.returnValue! as! [UFix64]
    let newGottenLockFee = newTeleportFees[0]
    let newGottenUnlockFee = newTeleportFees[1]
    Test.assertEqual(newGottenLockFee, newLockFee)
    Test.assertEqual(newGottenUnlockFee, newUnlockFee)
}