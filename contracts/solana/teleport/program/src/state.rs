//! State transition types

use {
    crate::error::TeleportError,
    borsh::{BorshDeserialize, BorshSerialize},
    solana_program::{msg, program_error::ProgramError, pubkey::Pubkey},
};

// BsBZoyMThoCCJAZR2nRyeCa3Tg2TyiDbAaNqeJxkqkHU
pub const OWNER: Pubkey = Pubkey::new_from_array([
    161, 111, 219, 59, 147, 221, 7, 127, 88, 42, 141, 30, 211, 69, 198, 108, 142, 249, 183, 249,
    92, 127, 241, 91, 118, 190, 46, 20, 186, 220, 132, 23,
]);

// D6vhDDD47LqHfHGps5YKkzJNBhXasrTf5LbNmkF3XHww
pub const MULTISIG_PROGRAM: Pubkey = Pubkey::new_from_array([
    179, 208, 219, 188, 251, 227, 215, 188, 180, 224, 242, 225, 39, 246, 138, 13, 26, 29, 195, 101,
    12, 247, 227, 6, 11, 98, 112, 139, 37, 42, 72, 2,
]);

pub const MAX_ADMIN: usize = 5;

/// Program states.
#[repr(C)]
#[derive(BorshSerialize, BorshDeserialize, PartialEq, Debug, Clone)]
pub struct Config {
    pub is_init: bool,
    pub is_frozen: bool,
    pub admins: [Pubkey; MAX_ADMIN],
}

impl Config {
    pub const LEN: usize = 162;

    pub fn add_admin(&mut self, add_admin_key: &Pubkey) -> Result<(), ProgramError> {
        for admin in &mut self.admins {
            if admin == &mut Pubkey::default() {
                *admin = *add_admin_key;
                return Ok(());
            }
        }
        msg!("admin list is full");
        Err(TeleportError::UnexpectedError.into())
    }

    pub fn remove_admin(&mut self, remove_admin_key: &Pubkey) -> Result<(), ProgramError> {
        for admin in &mut self.admins {
            if admin == remove_admin_key {
                *admin = Pubkey::default();
                return Ok(());
            }
        }
        msg!("key not found");
        Err(TeleportError::UnexpectedError.into())
    }

    pub fn contain_admin(&self, target: &Pubkey) -> bool {
        for admin in &self.admins {
            if admin == target {
                return true;
            }
        }
        false
    }
}

#[repr(C)]
#[derive(BorshSerialize, BorshDeserialize, PartialEq, Debug, Clone)]
pub struct Admin {
    pub is_init: bool,
    pub auth: Pubkey,
    pub allowance: u64,
}

impl Admin {
    pub const LEN: usize = 41;
}

#[repr(C)]
#[derive(BorshSerialize, BorshDeserialize, PartialEq, Debug, Clone)]
pub struct TeleportOutRecord {
    pub is_init: bool,
}

impl TeleportOutRecord {
    pub const LEN: usize = 1;
}
