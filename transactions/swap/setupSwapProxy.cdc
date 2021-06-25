import BltUsdtSwapPair from "../../contracts/flow/swap/BltUsdtSwapPair.cdc"

transaction {
  let proxy: @BltUsdtSwapPair.SwapProxy
  let holder: AuthAccount

  prepare(swapContractAccount: AuthAccount, proxyHolder: AuthAccount) {
    let adminRef = swapContractAccount.borrow<&BltUsdtSwapPair.Admin>(from: /storage/bltUsdtPairAdmin)
      ?? panic("Could not borrow a reference to Admin")

    self.proxy <- adminRef.createSwapProxy()

    assert(self.proxy != nil, message: "loaded proxy resource is nil")

    self.holder = proxyHolder
  }

  execute {
    self.holder.save(<-self.proxy, to: /storage/bltUsdtSwapProxy)

    let newSwapProxyRef = self.holder
      .borrow<&BltUsdtSwapPair.SwapProxy>(from: /storage/bltUsdtSwapProxy)
      ?? panic("Could not borrow a reference to new proxy holder")
  }
}
