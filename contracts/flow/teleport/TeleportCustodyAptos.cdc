import "FungibleToken"
import "BloctoToken"

access(all)
contract TeleportCustodyAptos {
  access(all)entitlement AdministratorEntitlement
  access(all)entitlement AdminEntitlement

  access(all)
  event TeleportAdminCreated(allowedAmount: UFix64)
  
  access(all)
  event Locked(amount: UFix64, to: [UInt8])
  
  access(all)
  event Unlocked(amount: UFix64, from: [UInt8], txHash: String)
  
  access(all)
  event FeeCollected(amount: UFix64, type: UInt8)
  
  access(all)
  let AdminStoragePath: StoragePath
  
  access(all)
  let TeleportAdminStoragePath: StoragePath
  
  access(all)
  let TeleportAdminTeleportUserPath: PublicPath
  
  access(all)
  let TeleportAdminTeleportControlPath: PrivatePath
  
  access(all)
  let teleportAddressLength: Int
  
  access(all)
  let teleportTxHashLength: Int
  
  access(all)
  var isFrozen: Bool
  
  access(contract)
  var unlocked: { String: Bool}
  
  access(contract)
  let lockVault: @BloctoToken.Vault
  
  access(all)
  resource Allowance { 
    access(all)
    var balance: UFix64
    
    init(balance: UFix64) { 
      self.balance = balance
    }
  }
  
  access(all)
  resource Administrator { 
    access(AdministratorEntitlement)
    fun createNewTeleportAdmin(allowedAmount: UFix64): @TeleportAdmin { 
      emit TeleportAdminCreated(allowedAmount: allowedAmount)
      return <-create TeleportAdmin(allowedAmount: allowedAmount)
    }
    
    access(AdministratorEntitlement)
    fun freeze() { 
      TeleportCustodyAptos.isFrozen = true
    }
    
    access(AdministratorEntitlement)
    fun unfreeze() { 
      TeleportCustodyAptos.isFrozen = false
    }
    
    access(AdministratorEntitlement)
    fun createAllowance(allowedAmount: UFix64): @Allowance { 
      return <-create Allowance(balance: allowedAmount)
    }
  }
  
  access(all)
  resource interface TeleportUser { 
    access(all)
    var lockFee: UFix64
    
    access(all)
    var unlockFee: UFix64
    
    access(all)
    var allowedAmount: UFix64
    
    access(all)
    fun lock(from: @{FungibleToken.Vault}, to: [UInt8]): Void
    
    access(all)
    fun depositAllowance(from: @Allowance)
  }
  
  access(all)
  resource interface TeleportControl { 
    access(AdminEntitlement)
    fun unlock(amount: UFix64, from: [UInt8], txHash: String): @{FungibleToken.Vault}
    
    access(AdminEntitlement)
    fun withdrawFee(amount: UFix64): @{FungibleToken.Vault}
    
    access(AdminEntitlement)
    fun updateLockFee(fee: UFix64)
    
    access(AdminEntitlement)
    fun updateUnlockFee(fee: UFix64)
  }
  
  access(all)
  resource TeleportAdmin: TeleportUser, TeleportControl { 
    access(all)
    var lockFee: UFix64
    
    access(all)
    var unlockFee: UFix64
    
    access(all)
    var allowedAmount: UFix64
    
    access(all)
    let feeCollector: @BloctoToken.Vault
    
    access(all)
    fun lock(from: @{FungibleToken.Vault}, to: [UInt8]) { 
      pre { 
        !TeleportCustodyAptos.isFrozen:
          "Teleport service is frozen"
        to.length == TeleportCustodyAptos.teleportAddressLength:
          "Teleport address should be teleportAddressLength bytes"
      }
      let vault <- from as! @BloctoToken.Vault
      let fee <- vault.withdraw(amount: self.lockFee)
      self.feeCollector.deposit(from: <-fee)
      let amount = vault.balance
      TeleportCustodyAptos.lockVault.deposit(from: <-vault)
      emit Locked(amount: amount, to: to)
      emit FeeCollected(amount: self.lockFee, type: 0)
    }
    
    access(AdminEntitlement)
    fun unlock(amount: UFix64, from: [UInt8], txHash: String): @{FungibleToken.Vault} { 
      pre { 
        !TeleportCustodyAptos.isFrozen:
          "Teleport service is frozen"
        amount <= self.allowedAmount:
          "Amount unlocked must be less than the allowed amount"
        amount > self.unlockFee:
          "Amount unlocked must be greater than unlock fee"
        from.length == TeleportCustodyAptos.teleportAddressLength:
          "Teleport address should be teleportAddressLength bytes"
        txHash.length == TeleportCustodyAptos.teleportTxHashLength:
          "Teleport tx hash should be teleportTxHashLength bytes"
        !(TeleportCustodyAptos.unlocked[txHash] ?? false):
          "Same unlock txHash has been executed"
      }
      self.allowedAmount = self.allowedAmount - amount
      TeleportCustodyAptos.unlocked[txHash] = true
      emit Unlocked(amount: amount, from: from, txHash: txHash)
      let vault <- TeleportCustodyAptos.lockVault.withdraw(amount: amount)
      let fee <- vault.withdraw(amount: self.unlockFee)
      self.feeCollector.deposit(from: <-fee)
      emit FeeCollected(amount: self.unlockFee, type: 1)
      return <-vault
    }
    
    access(AdminEntitlement)
    fun withdrawFee(amount: UFix64): @{FungibleToken.Vault} { 
      return <-self.feeCollector.withdraw(amount: amount)
    }
    
    access(AdminEntitlement)
    fun updateLockFee(fee: UFix64) { 
      self.lockFee = fee
    }
    
    access(AdminEntitlement)
    fun updateUnlockFee(fee: UFix64) { 
      self.unlockFee = fee
    }
    
    access(all)
    fun getFeeAmount(): UFix64 { 
      return self.feeCollector.balance
    }
    
    access(all)
    fun depositAllowance(from: @Allowance) { 
      self.allowedAmount = self.allowedAmount + from.balance
      destroy from
    }
    
    init(allowedAmount: UFix64) { 
      self.allowedAmount = allowedAmount
      self.feeCollector <- BloctoToken.createEmptyVault(vaultType: Type<@BloctoToken.Vault>()) as! @BloctoToken.Vault
      self.lockFee = 1.0
      self.unlockFee = 0.01
    }
  }
  
  access(all)
  fun getLockVaultBalance(): UFix64 { 
    return TeleportCustodyAptos.lockVault.balance
  }
  
  init() { 
    // Aptos address length
    self.teleportAddressLength = 32
    
    // Aptos tx hash length
    self.teleportTxHashLength = 64
    self.AdminStoragePath = /storage/teleportCustodyAptosAdmin
    self.TeleportAdminStoragePath = /storage/teleportCustodyAptosTeleportAdmin
    self.TeleportAdminTeleportUserPath = /public/teleportCustodyAptosTeleportUser
    self.TeleportAdminTeleportControlPath = /private/teleportCustodyAptosTeleportControl
    self.isFrozen = false
    self.unlocked = {} 
    self.lockVault <- BloctoToken.createEmptyVault(vaultType: Type<@BloctoToken.Vault>()) as! @BloctoToken.Vault
    let admin <- create Administrator()
    self.account.storage.save(<-admin, to: self.AdminStoragePath)
  }
}