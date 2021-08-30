import FungibleToken from "../token/FungibleToken.cdc"
import BloctoToken from "../token/BloctoToken.cdc"

pub contract TeleportCustodyBSC {

  pub event TeleportAdminCreated(allowedAmount: UFix64)
  pub event Locked(amount: UFix64, to: [UInt8])
  pub event Unlocked(amount: UFix64, from: [UInt8], txHash: String)
  pub event FeeCollected(amount: UFix64, type: UInt8)

  pub let AdminStoragePath: StoragePath
  pub let TeleportAdminStoragePath: StoragePath
  pub let TeleportAdminTeleportUserPath: PublicPath
  pub let TeleportAdminTeleportControlPath: PrivatePath
  pub let teleportAddressLength: Int
  pub let teleportTxHashLength: Int

  pub var isFrozen: Bool
  access(contract) var unlocked: {String: Bool}
  access(contract) let lockVault: @BloctoToken.Vault

  pub resource Allowance {
    pub var balance: UFix64

    init(balance: UFix64) {
      self.balance = balance
    }
  }

  pub resource Administrator {

    pub fun createNewTeleportAdmin(allowedAmount: UFix64): @TeleportAdmin {
      emit TeleportAdminCreated(allowedAmount: allowedAmount)
      return <- create TeleportAdmin(allowedAmount: allowedAmount)
    }

    pub fun freeze() {
      TeleportCustodyBSC.isFrozen = true
    }

    pub fun unfreeze() {
      TeleportCustodyBSC.isFrozen = false
    }

    pub fun createAllowance(allowedAmount: UFix64): @Allowance {
      return <- create Allowance(balance: allowedAmount)
    }
  }

  pub resource interface TeleportUser {
    pub var lockFee: UFix64

    pub var unlockFee: UFix64

    pub var allowedAmount: UFix64

    pub fun lock(from: @FungibleToken.Vault, to: [UInt8])

    pub fun depositAllowance(from: @Allowance)
  }

  pub resource interface TeleportControl {
    pub fun unlock(amount: UFix64, from: [UInt8], txHash: String): @FungibleToken.Vault

    pub fun withdrawFee(amount: UFix64): @FungibleToken.Vault

    pub fun updateLockFee(fee: UFix64)

    pub fun updateUnlockFee(fee: UFix64)
  }

  pub resource TeleportAdmin: TeleportUser, TeleportControl {
    pub var lockFee: UFix64

    pub var unlockFee: UFix64

    pub var allowedAmount: UFix64

    pub let feeCollector: @BloctoToken.Vault

    pub fun lock(from: @FungibleToken.Vault, to: [UInt8]) {
      pre {
        !TeleportCustodyBSC.isFrozen: "Teleport service is frozen"
        to.length == TeleportCustodyBSC.teleportAddressLength: "Teleport address should be teleportAddressLength bytes"
      }

      let vault <- from as! @BloctoToken.Vault
      let fee <- vault.withdraw(amount: self.lockFee)

      self.feeCollector.deposit(from: <-fee)

      let amount = vault.balance
      TeleportCustodyBSC.lockVault.deposit(from: <-vault)

      emit Locked(amount: amount, to: to)
      emit FeeCollected(amount: self.lockFee, type: 0)
    }

    pub fun unlock(amount: UFix64, from: [UInt8], txHash: String): @FungibleToken.Vault {
      pre {
        !TeleportCustodyBSC.isFrozen: "Teleport service is frozen"
        amount <= self.allowedAmount: "Amount unlocked must be less than the allowed amount"
        amount > self.unlockFee: "Amount unlocked must be greater than unlock fee"
        from.length == TeleportCustodyBSC.teleportAddressLength: "Teleport address should be teleportAddressLength bytes"
        txHash.length == TeleportCustodyBSC.teleportTxHashLength: "Teleport tx hash should be teleportTxHashLength bytes"
        !(TeleportCustodyBSC.unlocked[txHash] ?? false): "Same unlock txHash has been executed"
      }
      self.allowedAmount = self.allowedAmount - amount

      TeleportCustodyBSC.unlocked[txHash] = true
      emit Unlocked(amount: amount, from: from, txHash: txHash)

      let vault <- TeleportCustodyBSC.lockVault.withdraw(amount: amount)
      let fee <- vault.withdraw(amount: self.unlockFee)

      self.feeCollector.deposit(from: <-fee)
      emit FeeCollected(amount: self.unlockFee, type: 1)

      return <- vault
    }

    pub fun withdrawFee(amount: UFix64): @FungibleToken.Vault {
      return <- self.feeCollector.withdraw(amount: amount)
    }

    pub fun updateLockFee(fee: UFix64) {
      self.lockFee = fee
    }

    pub fun updateUnlockFee(fee: UFix64) {
      self.unlockFee = fee
    }

    pub fun getFeeAmount(): UFix64 {
      return self.feeCollector.balance
    }

    pub fun depositAllowance(from: @Allowance) {
      self.allowedAmount = self.allowedAmount + from.balance

      destroy from
    }

    init(allowedAmount: UFix64) {
      self.allowedAmount = allowedAmount

      self.feeCollector <- BloctoToken.createEmptyVault() as! @BloctoToken.Vault
      self.lockFee = 3.0
      self.unlockFee = 0.01
    }

    destroy() {
      destroy self.feeCollector
    }
  }

  pub fun getLockVaultBalance(): UFix64 {
    return TeleportCustodyBSC.lockVault.balance
  }

  init() {
    self.teleportAddressLength = 20
    self.teleportTxHashLength = 64
    self.AdminStoragePath = /storage/teleportCustodyAdmin
    self.TeleportAdminStoragePath = /storage/teleportCustodyBSCTeleportAdmin
    self.TeleportAdminTeleportUserPath = /public/teleportCustodyBSCTeleportUser
    self.TeleportAdminTeleportControlPath = /private/teleportCustodyBSCTeleportControl
  
    self.isFrozen = false
    self.unlocked = {}
    self.lockVault <- BloctoToken.createEmptyVault() as! @BloctoToken.Vault

    let admin <- create Administrator()
    self.account.save(<-admin, to: self.AdminStoragePath)
  }
}
