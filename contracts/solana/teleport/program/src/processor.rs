//! Program state processor

use {
    crate::{error::TeleportError, instruction::TeleportInstruction, state},
    borsh::{BorshDeserialize, BorshSerialize},
    solana_program::{
        account_info::next_account_info, account_info::AccountInfo, entrypoint::ProgramResult, msg,
        pubkey::Pubkey, rent::Rent, sysvar::Sysvar,
    },
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
            TeleportInstruction::InitAdmin { allowance } => {
                msg!("Instruction: InitAdmin");
                Self::process_init_admin(program_id, accounts, allowance)
            }
            TeleportInstruction::InitTeleportOutRecord => {
                msg!("Instruction: InitTeleportOutRecord");
                Self::process_init_teleport_out_record(program_id, accounts)
            }
            TeleportInstruction::AddAdmin { admin } => {
                msg!("Instruction: AddAdmin");
                Self::process_add_admin(program_id, accounts, &admin)
            }
            TeleportInstruction::RemoveAdmin { admin } => {
                msg!("Instruction: RemoveAdmin");
                Self::process_remove_admin(program_id, accounts, &admin)
            }
            TeleportInstruction::Freeze => {
                msg!("Instruction: Freeze");
                Self::process_freeze(program_id, accounts)
            }
            TeleportInstruction::Unfreeze => {
                msg!("Instruction: Unfreeze");
                Self::process_unfreeze(program_id, accounts)
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

    pub fn process_init_admin(
        _program_id: &Pubkey,
        accounts: &[AccountInfo],
        allowance: u64,
    ) -> ProgramResult {
        let account_info_iter = &mut accounts.iter();
        let owner_info = next_account_info(account_info_iter)?;
        let admin_info = next_account_info(account_info_iter)?;

        Self::only_owner(owner_info)?;

        let mut admin = state::Admin::try_from_slice(&admin_info.data.borrow())?;
        if admin.is_init {
            return Err(TeleportError::AlreadyInUse.into());
        }

        admin.is_init = true;
        admin.allowance = allowance;

        admin
            .serialize(&mut *admin_info.data.borrow_mut())
            .map_err(|e| e.into())
    }

    pub fn process_init_teleport_out_record(
        _program_id: &Pubkey,
        accounts: &[AccountInfo],
    ) -> ProgramResult {
        let account_info_iter = &mut accounts.iter();
        let record_info = next_account_info(account_info_iter)?;

        let mut record = state::TeleportOutRecord::try_from_slice(&record_info.data.borrow())?;
        if record.is_init {
            return Err(TeleportError::AlreadyInUse.into());
        }

        record.is_init = true;
        record
            .serialize(&mut *record_info.data.borrow_mut())
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

    pub fn process_remove_admin(
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

        config.remove_admin(admin)?;

        config
            .serialize(&mut *config_info.data.borrow_mut())
            .map_err(|e| e.into())
    }

    pub fn process_freeze(_program_id: &Pubkey, accounts: &[AccountInfo]) -> ProgramResult {
        let account_info_iter = &mut accounts.iter();
        let owner_info = next_account_info(account_info_iter)?;
        let config_info = next_account_info(account_info_iter)?;

        Self::only_owner(owner_info)?;

        let mut config = state::Config::try_from_slice(&config_info.data.borrow())?;
        if !config.is_init {
            return Err(TeleportError::IncorrectProgramAccount.into());
        }

        config.is_frozen = true;

        config
            .serialize(&mut *config_info.data.borrow_mut())
            .map_err(|e| e.into())
    }

    pub fn process_unfreeze(_program_id: &Pubkey, accounts: &[AccountInfo]) -> ProgramResult {
        let account_info_iter = &mut accounts.iter();
        let owner_info = next_account_info(account_info_iter)?;
        let config_info = next_account_info(account_info_iter)?;

        Self::only_owner(owner_info)?;

        let mut config = state::Config::try_from_slice(&config_info.data.borrow())?;
        if !config.is_init {
            return Err(TeleportError::IncorrectProgramAccount.into());
        }

        config.is_frozen = false;

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
