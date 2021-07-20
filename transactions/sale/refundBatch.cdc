import BloctoTokenSale from "../../contracts/flow/sale/BloctoTokenSale.cdc"

transaction(addresses: [Address]) {

    // The reference to the Admin Resource
    let adminRef: &BloctoTokenSale.Admin

    prepare(account: AuthAccount) {

        // Get admin reference
        self.adminRef = account.borrow<&BloctoTokenSale.Admin>(from: BloctoTokenSale.SaleAdminStoragePath)
			?? panic("Could not borrow reference to the admin!")
    }

    execute {

        // Refun BLT purchase to all addresses in the list
        for address in addresses {
            self.adminRef.refund(address: address)
        }
    }
}
