import BloctoDAO from "../../contracts/flow/dao/BloctoDAO.cdc"

pub fun main(address: Address): UFix64 {
  return BloctoDAO.getStakedBLT(address: address)
}