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
    GetOwner,
}

pub fn get_owner(program_id: &Pubkey) -> Result<Instruction, ProgramError> {
    let init_data = TeleportInstruction::GetOwner {};
    let data = init_data.try_to_vec()?;
    let accounts = vec![];
    Ok(Instruction {
        program_id: *program_id,
        accounts,
        data,
    })
}
