import BloctoDAO from "../../contracts/flow/dao/BloctoDAO.cdc"

transaction {

  prepare(signer: AuthAccount) {
    let admin = signer
      .borrow<&BloctoDAO.Admin>(from: BloctoDAO.AdminStoragePath)
      ?? panic("Signer is not the admin")

    let proposer <- admin.createProposer()

    signer.save(<-proposer, to: /storage/bloctoDAOProposer)
    signer.link<&BloctoDAO.Proposer>(
      /private/bloctoDAOProposer,
      target: /storage/bloctoDAOProposer
    )
  }
}
