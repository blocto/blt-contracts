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
            TeleportInstruction::InitConfig => {
                msg!("Instruction: InitConfig");
                Self::process_init_config(program_id, accounts)
            }
            TeleportInstruction::AddAdmin { admin } => {
                msg!("Instruction: AddAdmin");
                Self::process_add_admin(program_id, accounts, &admin)
            }
        }
    }

    pub fn process_init_config(_program_id: &Pubkey, accounts: &[AccountInfo]) -> ProgramResult {
        let account_info_iter = &mut accounts.iter();
        let owner_info = next_account_info(account_info_iter)?;
        let config_info = next_account_info(account_info_iter)?;
        let rent_info = next_account_info(account_info_iter)?;
        let rent = &Rent::from_account_info(rent_info)?;

        Self::only_owner(owner_info)?;

        let mut config = state::Config::try_from_slice(&config_info.data.borrow())?;
        if config.is_init {
            return Err(TeleportError::AlreadyInUse.into());
        }
        if !rent.is_exempt(config_info.lamports(), config_info.data_len()) {
            return Err(TeleportError::NotRentExempt.into());
        }

        config.is_init = true;

        config
            .serialize(&mut *config_info.data.borrow_mut())
            .map_err(|e| e.into())
    }

    pub fn process_add_admin(
        _program_id: &Pubkey,
        accounts: &[AccountInfo],
        admin: &Pubkey,
    ) -> ProgramResult {
        let account_info_iter = &mut accounts.iter();
        let owner_info = next_account_info(account_info_iter)?;
        let config_info = next_account_info(account_info_iter)?;

        Self::only_owner(owner_info)?;

        let mut config = state::Config::try_from_slice(&config_info.data.borrow())?;
        if !config.is_init {
            return Err(TeleportError::IncorrectProgramAccount.into());
        }

        config.add_admin(admin)?;

        config
            .serialize(&mut *config_info.data.borrow_mut())
            .map_err(|e| e.into())
    }

    fn only_owner(account_info: &AccountInfo) -> ProgramResult {
        if account_info.key != &state::OWNER {
            msg!("owner mismatch");
            return Err(TeleportError::AuthFailed.into());
        }

        if !account_info.is_signer {
            msg!("owner should be a singer");
            return Err(TeleportError::AuthFailed.into());
        }

        Ok(())
    }
}
