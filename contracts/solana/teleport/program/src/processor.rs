//! Program state processor

use crate::{error::TeleportError, instruction::TeleportInstruction, state};
use borsh::{BorshDeserialize, BorshSerialize};
use solana_program::{
    account_info::next_account_info,
    account_info::AccountInfo,
    clock::{Clock, Slot},
    entrypoint::ProgramResult,
    msg,
    program::{invoke, invoke_signed},
    program_error::ProgramError,
    program_pack::{IsInitialized, Pack},
    pubkey::Pubkey,
    rent::Rent,
    sysvar::Sysvar,
};

/// Program state handler.
pub struct Processor {}
impl Processor {
    /// Processes an instruction
    pub fn process_instruction(
        program_id: &Pubkey,
        accounts: &[AccountInfo],
        input: &[u8],
    ) -> ProgramResult {
        let instruction = TeleportInstruction::try_from_slice(input)?;
        match instruction {
            TeleportInstruction::GetOwner => {
                msg!("Instruction: GetOwner");
                msg!(&format!("owner is {}", state::OWNER.to_string()));
                Ok(())
            }
        }
    }
}
