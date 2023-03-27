import FungibleToken from "../../contracts/flow/token/FungibleToken.cdc"
import FlowToken from "../../contracts/flow/token/FlowToken.cdc"

pub fun main(address: Address): Bool {
  return getAccount(address).getCapability<&{FungibleToken.Provider}>(/public/flowTokenReceiver).check()
}
