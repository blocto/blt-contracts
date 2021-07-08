import NonFungibleToken from "../../../contracts/flow/token/NonFungibleToken.cdc"
import BloctoPass from "../../../contracts/flow/token/BloctoPass.cdc"

transaction() {

    prepare(signer: AuthAccount) {
        let minter = signer
            .borrow<&BloctoPass.NFTMinter>(from: BloctoPass.MinterStoragePath)
            ?? panic("Signer is not the admin")

        // Thursday, July 15, 2021 8:00:00 AM GMT
        let saleDate = 1626336000.0
        let months = 30.0 * 24.0 * 60.0 * 60.0 // seconds

        // Lockup schedule for BLT community sale
        let lockupSchedule = {
            0.0                      : 1.0,
            saleDate                 : 1.0,
            saleDate + 6.0 * months  : 17.0 / 18.0,
            saleDate + 7.0 * months  : 16.0 / 18.0,
            saleDate + 8.0 * months  : 15.0 / 18.0,
            saleDate + 9.0 * months  : 14.0 / 18.0,
            saleDate + 10.0 * months : 13.0 / 18.0,
            saleDate + 11.0 * months : 12.0 / 18.0,
            saleDate + 12.0 * months : 11.0 / 18.0,
            saleDate + 13.0 * months : 10.0 / 18.0,
            saleDate + 14.0 * months : 9.0 / 18.0,
            saleDate + 15.0 * months : 8.0 / 18.0,
            saleDate + 16.0 * months : 7.0 / 18.0,
            saleDate + 17.0 * months : 6.0 / 18.0,
            saleDate + 18.0 * months : 5.0 / 18.0,
            saleDate + 19.0 * months : 4.0 / 18.0,
            saleDate + 20.0 * months : 3.0 / 18.0,
            saleDate + 21.0 * months : 2.0 / 18.0,
            saleDate + 22.0 * months : 1.0 / 18.0,
            saleDate + 23.0 * months : 0.0
        }

        minter.setupPredefinedLockupSchedule(lockupSchedule: lockupSchedule)
    }
}
