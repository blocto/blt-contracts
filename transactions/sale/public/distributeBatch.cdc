import BloctoTokenPublicSale from "../../../contracts/flow/sale/BloctoTokenPublicSale.cdc"

transaction(addresses: [Address], allocationAmounts: [UFix64]) {

    // The reference to the Admin Resource
    let adminRef: &BloctoTokenPublicSale.Admin

    prepare(account: AuthAccount) {
        assert(
            addresses.length == allocationAmounts.length,
            message: "Input length mismatch"
        )

        // Get admin reference
        self.adminRef = account.borrow<&BloctoTokenPublicSale.Admin>(from: BloctoTokenPublicSale.SaleAdminStoragePath)
			?? panic("Could not borrow reference to the admin!")
    }

    execute {

        // Distribute BLT purchase to all addresses in the list
        var index = 0
        while index < addresses.length {
            self.adminRef.distribute(address: addresses[index], allocationAmount: allocationAmounts[index])
            index = index + 1
        }
    }
}
