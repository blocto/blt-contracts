//! State transition types

use {
    borsh::{BorshDeserialize, BorshSerialize},
    solana_program::pubkey::Pubkey,
};

// BsBZoyMThoCCJAZR2nRyeCa3Tg2TyiDbAaNqeJxkqkHU
pub const OWNER: Pubkey = Pubkey::new_from_array([
    161, 111, 219, 59, 147, 221, 7, 127, 88, 42, 141, 30, 211, 69, 198, 108, 142, 249, 183, 249,
    92, 127, 241, 91, 118, 190, 46, 20, 186, 220, 132, 23,
]);

/// Program states.
#[repr(C)]
#[derive(BorshSerialize, BorshDeserialize, PartialEq, Debug, Clone)]
pub struct Hello {}
