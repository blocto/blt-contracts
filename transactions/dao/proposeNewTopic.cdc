import BloctoDAO from "../../contracts/flow/dao/BloctoDAO.cdc"

transaction {
  let proposer: &BloctoDAO.Proposer

  prepare(signer: AuthAccount) {
    self.proposer = signer.getCapability(/private/bloctoDAOProposer).borrow<&BloctoDAO.Proposer>()
	    ?? panic("Could not borrow reference")
  }

  execute {
    self.proposer.addTopic(
      title: "How much $BLT token grant should the Blocto ecosystem fund allocate for the IDO platform from portto, the infrastructure supplier?",
      description: "Portto is the infrastructure supplier of Blocto's upcoming IDO platform. In this poll, we wish to decide how much $BLT token should be granted to portto for developing the Blocto IDO platform via BloctoDAO. The grant will be granted from the ecosystem fund.", 
      options: ["100K $BLT", "300K $BLT", "500K $BLT"],
      startAt: 1641373200.0,
      endAt: 1641546000.0,
      minVoteStakingAmount: 0.00000001
    )
  }
}
