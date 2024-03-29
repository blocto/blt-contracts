import BloctoTokenPublicSale from "../../../contracts/flow/sale/BloctoTokenPublicSale.cdc"

transaction(address: Address) {

    // The reference to the Admin Resource
    let adminRef: &BloctoTokenPublicSale.Admin

    prepare(account: AuthAccount) {

        // Get admin reference
        self.adminRef = account.borrow<&BloctoTokenPublicSale.Admin>(from: BloctoTokenPublicSale.SaleAdminStoragePath)
			?? panic("Could not borrow reference to the admin!")
    }

    execute {

        // Refun BLT purchase
        self.adminRef.refund(address: address)
    }
}
