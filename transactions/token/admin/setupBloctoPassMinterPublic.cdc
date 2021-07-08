import BloctoPass from "../../../contracts/flow/token/BloctoPass.cdc"

transaction {
    prepare(signer: AuthAccount) {
        // create a public capability to mint Blocto Pass
        signer.link<&{BloctoPass.MinterPublic}>(
            BloctoPass.MinterPublicPath,
            target: BloctoPass.MinterStoragePath
        )
    }
}
