import BloctoTokenPublicSale from "../../../contracts/flow/sale/BloctoTokenPublicSale.cdc"

transaction(addresses: [Address]) {

    // The reference to the Admin Resource
    let adminRef: &BloctoTokenPublicSale.Admin

    prepare(account: AuthAccount) {

        // Get admin reference
        self.adminRef = account.borrow<&BloctoTokenPublicSale.Admin>(from: BloctoTokenPublicSale.SaleAdminStoragePath)
			?? panic("Could not borrow reference to the admin!")
    }

    execute {

        // Distribute BLT purchase to all addresses in the list
        for address in addresses {
            self.adminRef.distribute(address: address)
        }
    }
}
