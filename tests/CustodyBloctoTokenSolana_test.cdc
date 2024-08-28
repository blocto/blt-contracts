import Test
import "TeleportCustodySolana"

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
        name: "TeleportCustodySolana",
        path: "../contracts/flow/teleport/TeleportCustodySolana.cdc",
        arguments: [],
    )
    Test.expect(err2, Test.beNil())
}

access(all) fun testCreateTeleportAdmin() {
    let createTeleportAdminCode = Test.readFile("../transactions/teleport/Solana/createTeleportAdminSolana.cdc")
    let createTeleportAdminTx = Test.Transaction(
        code: createTeleportAdminCode,
        authorizers: [admin.address, teleportAdmin.address],
        signers: [admin, teleportAdmin],
        arguments: [1000.0],
    )
    let createTeleportAdminTxResult = Test.executeTransaction(createTeleportAdminTx)
    Test.expect(createTeleportAdminTxResult, Test.beSucceeded())
}

access(all) fun testDepositAllowanceSolana() {
    let depositAllowanceSolanaCode = Test.readFile("../transactions/teleport/Solana/depositAllowanceSolana.cdc")
    let depositAllowanceTx = Test.Transaction(
        code: depositAllowanceSolanaCode,
        authorizers: [admin.address],
        signers: [admin],
        arguments: [teleportAdmin.address, 1000.0],
    )
    let depositAllowanceTxResult = Test.executeTransaction(depositAllowanceTx)
    Test.expect(depositAllowanceTxResult, Test.beSucceeded())
}

access(all) fun testAllowance() {
    let getAllowanceScript = Test.readFile("../scripts/teleport/Solana/getAllowanceSolana.cdc")
    let resultBefore = Test.executeScript(getAllowanceScript, [teleportAdmin.address])
    let allowanceBefore = resultBefore.returnValue! as! UFix64
    Test.assertEqual(2000.0, allowanceBefore)

    testDepositAllowanceSolana()
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

access(all) fun testLockTokensSolana() {
    let to = "418e1f1c9989975be0a08e52798ddb1154535882b410f636932af11a5944adf7"
    testSetupBloctoTokenVault()
    let lockTokensSolanaCode = Test.readFile("../transactions/teleport/Solana/lockTokensSolana.cdc")
    let lockTokensSolanaTx = Test.Transaction(
        code: lockTokensSolanaCode,
        authorizers: [receiver.address],
        signers: [receiver],
        arguments: [teleportAdmin.address, 5.0, to, "SOL"]
    )
    let lockTokenTxResult = Test.executeTransaction(lockTokensSolanaTx)
    Test.expect(lockTokenTxResult, Test.beSucceeded())

    let lockedEvents = Test.eventsOfType(Type<TeleportCustodySolana.Locked>())
    Test.assertEqual(1, lockedEvents.length)
    let lockedEvent = lockedEvents[0] as! TeleportCustodySolana.Locked
    Test.assertEqual(2.0, lockedEvent.amount)
    Test.assertEqual(to.decodeHex(), lockedEvent.to)
    Test.assertEqual("SOL", lockedEvent.toAddressType)
}

access(all) fun testUnlockTokensSolana() {
    let from = "418e1f1c9989975be0a08e52798ddb1154535882b410f636932af11a5944adf7"
    let txHash = "58376f820065f220205a64ced642f822593adeb6cfd597e56c31d64326ab1b58b422bda7895aced44a333049c6deca3ab05c68230027cbf32ab0c87be56f1406"
    let unlockTokensSolanaCode = Test.readFile("../transactions/teleport/Solana/unlockTokensSolana.cdc")
    let unlockTokensSolanaTx = Test.Transaction(
        code: unlockTokensSolanaCode,
        authorizers: [teleportAdmin.address],
        signers: [teleportAdmin],
        arguments: [2.0, receiver.address, from, txHash]
    )
    let unlockTokenTxResult = Test.executeTransaction(unlockTokensSolanaTx)
    Test.expect(unlockTokenTxResult, Test.beSucceeded())

    let unlockedEvents = Test.eventsOfType(Type<TeleportCustodySolana.Unlocked>())
    Test.assertEqual(1, unlockedEvents.length)
    let unlockedEvent = unlockedEvents[0] as! TeleportCustodySolana.Unlocked
    Test.assertEqual(2.0, unlockedEvent.amount)
    Test.assertEqual(from.decodeHex(), unlockedEvent.from)
    Test.assertEqual(txHash, unlockedEvent.txHash)
}

access(all) fun testTransferTeleportFeesSolana() {
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

    let transferTeleportFeesCode = Test.readFile("../transactions/teleport/Solana/transferTeleportFeesSolana.cdc")
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

access(all) fun testUpdateTeleportFeesSolana() {
    let teleportFeesScript = Test.readFile("../scripts/teleport/Solana/getTeleportFeesSolana.cdc")
    let result = Test.executeScript(teleportFeesScript, [teleportAdmin.address])
    let teleportFees = result.returnValue! as! [UFix64]
    let lockFee = teleportFees[0]
    let unlockFee = teleportFees[1]
    Test.assertEqual(3.0, lockFee)
    Test.assertEqual(0.01, unlockFee)

    let newLockFee = 5.0
    let newUnlockFee = 0.02
    let updateTeleportFeeCode = Test.readFile("../transactions/teleport/Solana/updateTeleportFeesSolana.cdc")
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