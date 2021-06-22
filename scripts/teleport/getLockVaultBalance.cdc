import TeleportCustody from "../../contracts/flow/teleport/TeleportCustody.cdc"

pub fun main(): UFix64 {
    return TeleportCustody.getLockVaultBalance()
}
