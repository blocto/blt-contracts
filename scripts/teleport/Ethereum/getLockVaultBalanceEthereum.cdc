import TeleportCustodyEthereum from "../../contracts/flow/teleport/TeleportCustodyEthereum.cdc"

pub fun main(): UFix64 {
    return TeleportCustodyEthereum.getLockVaultBalance()
}
