//! Program state processor

use {
    crate::{error::TeleportError, instruction::TeleportInstruction, state},
    borsh::{BorshDeserialize, BorshSerialize},
    solana_program::{
        account_info::next_account_info,
        account_info::AccountInfo,
        entrypoint::ProgramResult,
        instruction::{AccountMeta, Instruction},
        msg,
        program::{invoke, invoke_signed},
        program_error::ProgramError,
        program_pack::Pack,
        pubkey::Pubkey,
        rent::Rent,
        system_instruction,
        sysvar::Sysvar,
    },
    spl_token,
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
            TeleportInstruction::TeleportIn { amount, decimals } => {
                msg!("Instruction: TeleportIn");
                Self::process_teleport_in(program_id, accounts, amount, decimals)
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

    pub fn process_teleport_in(
        program_id: &Pubkey,
        accounts: &[AccountInfo],
        amount: u64,
        decimals: u8,
    ) -> ProgramResult {
        let account_info_iter = &mut accounts.iter();
        let config_info = next_account_info(account_info_iter)?;
        let wallet_info = next_account_info(account_info_iter)?;
        let wallet_pda_info = next_account_info(account_info_iter)?;
        let wallet_signer_info = next_account_info(account_info_iter)?;
        let fee_payer_info = next_account_info(account_info_iter)?;
        let wallet_program_info = next_account_info(account_info_iter)?;
        let from_info = next_account_info(account_info_iter)?;
        let mint_info = next_account_info(account_info_iter)?;
        let from_auth_info = next_account_info(account_info_iter)?;
        let spl_token_program_info = next_account_info(account_info_iter)?;

        let config = Self::get_config(program_id, config_info)?;
        if config.is_frozen {
            return Err(TeleportError::Freeze.into());
        }

        // check wallet program
        if wallet_program_info.key != &state::MULTISIG_PROGRAM {
            msg!("unexpected multisig program");
            return Err(TeleportError::UnexpectedError.into());
        }

        // check token program
        if spl_token_program_info.key != &spl_token::id() {
            msg!("unexpected spl-token-program");
            return Err(TeleportError::UnexpectedError.into());
        }

        let seeds: &[&[_]] = &[
            b"BLT",
            &[Pubkey::find_program_address(&[b"BLT"], &program_id).1],
        ];

        let mut data = vec![3, 3, 3, 0, 5, 1, 6, 1, 7, 2, 15];
        data.extend(amount.to_le_bytes().iter().cloned());
        data.push(decimals);

        invoke_signed(
            &Instruction::new_with_bytes(
                *wallet_program_info.key,
                &data[..],
                vec![
                    AccountMeta::new(*wallet_info.key, false),
                    AccountMeta::new_readonly(*wallet_pda_info.key, false),
                    AccountMeta::new(*fee_payer_info.key, true),
                    AccountMeta::new_readonly(*spl_token_program_info.key, false),
                    AccountMeta::new_readonly(*wallet_signer_info.key, true),
                    AccountMeta::new(*from_info.key, false),
                    AccountMeta::new(*mint_info.key, false),
                    AccountMeta::new_readonly(*from_auth_info.key, true),
                ],
            ),
            &[
                wallet_info.clone(),
                wallet_pda_info.clone(),
                fee_payer_info.clone(),
                spl_token_program_info.clone(),
                wallet_signer_info.clone(),
                wallet_program_info.clone(),
                from_info.clone(),
                mint_info.clone(),
                from_auth_info.clone(),
            ],
            &[&seeds],
        )?;

        Ok(())
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

    fn get_config(
        program_id: &Pubkey,
        config_info: &AccountInfo,
    ) -> Result<state::Config, ProgramError> {
        if config_info.owner != program_id {
            return Err(TeleportError::IncorrectProgramAccount.into());
        }

        if config_info.data_len() != state::Config::LEN {
            return Err(TeleportError::IncorrectProgramAccount.into());
        }

        let config = state::Config::try_from_slice(&config_info.data.borrow())?;
        if !config.is_init {
            return Err(TeleportError::UninitializedAccount.into());
        }

        return Ok(config);
    }
}
