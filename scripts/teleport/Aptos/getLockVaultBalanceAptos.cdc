import TeleportCustodyAptos from "../../contracts/flow/teleport/TeleportCustodyAptos.cdc"

pub fun main(): UFix64 {
    return TeleportCustodyAptos.getLockVaultBalance()
}
