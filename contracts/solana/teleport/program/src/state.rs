//! State transition types

use {
    crate::error::TeleportError,
    borsh::{BorshDeserialize, BorshSerialize},
    solana_program::{msg, program_error::ProgramError, pubkey::Pubkey},
};

// TODO use env!
pub const OWNER_KEY: &str = "BsBZoyMThoCCJAZR2nRyeCa3Tg2TyiDbAaNqeJxkqkHU";

// TODO use env!
pub const MULTISIG_PROGRAM_KEY: &str = "D6vhDDD47LqHfHGps5YKkzJNBhXasrTf5LbNmkF3XHww";

// TODO use env!
pub const BLT_MINT_KEY: &str = "BLT1noyNr3GttckEVrtcfC6oyK6yV1DpPgSyXbncMwef";

pub const SIGNER_SEED: &[u8] = b"BLT";

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
