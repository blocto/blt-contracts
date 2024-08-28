import TeleportCustodyBSC from "../../contracts/flow/teleport/TeleportCustodyBSC.cdc"

pub fun main(): UFix64 {
    return TeleportCustodyBSC.getLockVaultBalance()
}
