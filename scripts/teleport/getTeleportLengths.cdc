import TeleportCustody from "../../contracts/flow/teleport/TeleportCustody.cdc"

pub fun main(): [Int] {
    return [TeleportCustody.teleportAddressLength, TeleportCustody.teleportTxHashLength]
}
