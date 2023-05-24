import BloctoPass from "../../../contracts/flow/token/BloctoPass.cdc"

transaction {
    prepare(signer: AuthAccount) {
        // create a public capability to mint Blocto Pass
        signer.link<&{BloctoPass.MinterPublic}>(
            /public/bloctoPassMinter,
            target: BloctoPass.MinterStoragePath
        )
    }
}
