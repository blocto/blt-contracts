import BloctoTokenSale from "../../contracts/flow/sale/BloctoTokenSale.cdc"

transaction(address: Address) {

    // The reference to the Admin Resource
    let adminRef: &BloctoTokenSale.Admin

    prepare(account: AuthAccount) {

        // Get admin reference
        self.adminRef = account.borrow<&BloctoTokenSale.Admin>(from: BloctoTokenSale.SaleAdminStoragePath)
			?? panic("Could not borrow reference to the admin!")
    }

    execute {

        // Distribute BLT purchase
        self.adminRef.distribute(address: address)
    }
}
