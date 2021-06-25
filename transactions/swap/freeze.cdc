import BltUsdtSwapPair from "../../contracts/flow/swap/BltUsdtSwapPair.cdc"

transaction() {
  prepare(fspAdmin: AuthAccount) {

    let adminRef = fspAdmin.borrow<&BltUsdtSwapPair.Admin>(from: /storage/bltUsdtPairAdmin)
        ?? panic("Could not borrow a reference to Admin")

    adminRef.freeze()
  }
}
