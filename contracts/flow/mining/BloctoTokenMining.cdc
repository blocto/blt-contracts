import FungibleToken from "../token/FungibleToken.cdc"
import BloctoToken from "../token/BloctoToken.cdc"

pub contract BloctoTokenMining {
    pub var rewardsDistributed: {Address: UInt64}

}
