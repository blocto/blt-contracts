//! Instruction types

use borsh::{BorshDeserialize, BorshSerialize};
use solana_program::{
    clock::Slot,
    instruction::{AccountMeta, Instruction},
    program_error::ProgramError,
    pubkey::Pubkey,
    sysvar,
};

#[derive(BorshSerialize, BorshDeserialize, PartialEq, Debug, Clone)]
pub enum TeleportInstruction {
    Hello,
}
