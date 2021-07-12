import NonFungibleToken from "../../../contracts/flow/token/NonFungibleToken.cdc"
import BloctoPass from "../../../contracts/flow/token/BloctoPass.cdc"

transaction() {

    prepare(signer: AuthAccount) {
        let minter = signer
            .borrow<&BloctoPass.NFTMinter>(from: BloctoPass.MinterStoragePath)
            ?? panic("Signer is not the admin")

        // July 22, 2021 00:00:00 AM GMT
        let saleDate = 1626912000.0
        let months = 30.0 * 24.0 * 60.0 * 60.0 // seconds

        // Lockup schedule for Blocto founders
        let lockupSchedule = {
            0.0                      : 1.0,
            saleDate                 : 1.0,
            saleDate + 6.0 * months  : 41.0 / 42.0,
            saleDate + 7.0 * months  : 40.0 / 42.0,
            saleDate + 8.0 * months  : 39.0 / 42.0,
            saleDate + 9.0 * months  : 38.0 / 42.0,
            saleDate + 10.0 * months : 37.0 / 42.0,
            saleDate + 11.0 * months : 36.0 / 42.0,
            saleDate + 12.0 * months : 35.0 / 42.0,
            saleDate + 13.0 * months : 34.0 / 42.0,
            saleDate + 14.0 * months : 33.0 / 42.0,
            saleDate + 15.0 * months : 32.0 / 42.0,
            saleDate + 16.0 * months : 31.0 / 42.0,
            saleDate + 17.0 * months : 30.0 / 42.0,
            saleDate + 18.0 * months : 29.0 / 42.0,
            saleDate + 19.0 * months : 28.0 / 42.0,
            saleDate + 20.0 * months : 27.0 / 42.0,
            saleDate + 21.0 * months : 26.0 / 42.0,
            saleDate + 22.0 * months : 25.0 / 42.0,
            saleDate + 23.0 * months : 24.0 / 42.0,
            saleDate + 24.0 * months : 23.0 / 42.0,
            saleDate + 25.0 * months : 22.0 / 42.0,
            saleDate + 26.0 * months : 21.0 / 42.0,
            saleDate + 27.0 * months : 20.0 / 42.0,
            saleDate + 28.0 * months : 19.0 / 42.0,
            saleDate + 29.0 * months : 18.0 / 42.0,
            saleDate + 30.0 * months : 17.0 / 42.0,
            saleDate + 31.0 * months : 16.0 / 42.0,
            saleDate + 32.0 * months : 15.0 / 42.0,
            saleDate + 33.0 * months : 14.0 / 42.0,
            saleDate + 34.0 * months : 13.0 / 42.0,
            saleDate + 35.0 * months : 12.0 / 42.0,
            saleDate + 36.0 * months : 11.0 / 42.0,
            saleDate + 37.0 * months : 10.0 / 42.0,
            saleDate + 38.0 * months : 9.0 / 42.0,
            saleDate + 39.0 * months : 8.0 / 42.0,
            saleDate + 40.0 * months : 7.0 / 42.0,
            saleDate + 41.0 * months : 6.0 / 42.0,
            saleDate + 42.0 * months : 5.0 / 42.0,
            saleDate + 43.0 * months : 4.0 / 42.0,
            saleDate + 44.0 * months : 3.0 / 42.0,
            saleDate + 45.0 * months : 2.0 / 42.0,
            saleDate + 46.0 * months : 1.0 / 42.0,
            saleDate + 47.0 * months : 0.0
        }

        minter.setupPredefinedLockupSchedule(lockupSchedule: lockupSchedule)
    }
}
