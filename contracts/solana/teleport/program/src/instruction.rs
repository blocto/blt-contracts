//! Instruction types

use {
    borsh::{BorshDeserialize, BorshSerialize},
    solana_program::{
        instruction::{AccountMeta, Instruction},
        program_error::ProgramError,
        pubkey::Pubkey,
        sysvar,
    },
};

#[derive(BorshSerialize, BorshDeserialize, PartialEq, Debug, Clone)]
pub enum TeleportInstruction {
    GetOwner,
    InitConfig,
    InitAdmin { allowance: u64 },
    InitTeleportOutRecord,
    AddAdmin { admin: Pubkey },
    RemoveAdmin { admin: Pubkey },
    Freeze,
    Unfreeze,
    TeleportIn { amount: u64, decimals: u8 },
    TeleportOut { tx_hash: [u8; 32], amount: u64, decimals: u8 },
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

pub fn init_config(
    program_id: &Pubkey,
    owner: &Pubkey,
    config: &Pubkey,
) -> Result<Instruction, ProgramError> {
    let init_data = TeleportInstruction::InitConfig {};
    let data = init_data.try_to_vec()?;
    let accounts = vec![
        AccountMeta::new(*owner, true),
        AccountMeta::new(*config, false),
        AccountMeta::new_readonly(sysvar::rent::id(), false),
    ];
    Ok(Instruction {
        program_id: *program_id,
        accounts,
        data,
    })
}

pub fn init_admin(
    program_id: &Pubkey,
    owner: &Pubkey,
    admin: &Pubkey,
    allowance: u64,
) -> Result<Instruction, ProgramError> {
    let init_data = TeleportInstruction::InitAdmin { allowance };
    let data = init_data.try_to_vec()?;
    let accounts = vec![
        AccountMeta::new(*owner, true),
        AccountMeta::new(*admin, false),
    ];
    Ok(Instruction {
        program_id: *program_id,
        accounts,
        data,
    })
}

pub fn init_teleport_out_record(
    program_id: &Pubkey,
    record: &Pubkey,
) -> Result<Instruction, ProgramError> {
    let init_data = TeleportInstruction::InitTeleportOutRecord {};
    let data = init_data.try_to_vec()?;
    let accounts = vec![AccountMeta::new(*record, false)];
    Ok(Instruction {
        program_id: *program_id,
        accounts,
        data,
    })
}

pub fn add_admin(
    program_id: &Pubkey,
    owner: &Pubkey,
    config: &Pubkey,
    admin: &Pubkey,
) -> Result<Instruction, ProgramError> {
    let init_data = TeleportInstruction::AddAdmin { admin: *admin };
    let data = init_data.try_to_vec()?;
    let accounts = vec![
        AccountMeta::new(*owner, true),
        AccountMeta::new(*config, false),
    ];
    Ok(Instruction {
        program_id: *program_id,
        accounts,
        data,
    })
}

pub fn remove_admin(
    program_id: &Pubkey,
    owner: &Pubkey,
    config: &Pubkey,
    admin: &Pubkey,
) -> Result<Instruction, ProgramError> {
    let init_data = TeleportInstruction::RemoveAdmin { admin: *admin };
    let data = init_data.try_to_vec()?;
    let accounts = vec![
        AccountMeta::new(*owner, true),
        AccountMeta::new(*config, false),
    ];
    Ok(Instruction {
        program_id: *program_id,
        accounts,
        data,
    })
}

pub fn freeze(
    program_id: &Pubkey,
    owner: &Pubkey,
    config: &Pubkey,
) -> Result<Instruction, ProgramError> {
    let init_data = TeleportInstruction::Freeze {};
    let data = init_data.try_to_vec()?;
    let accounts = vec![
        AccountMeta::new(*owner, true),
        AccountMeta::new(*config, false),
    ];
    Ok(Instruction {
        program_id: *program_id,
        accounts,
        data,
    })
}

pub fn unfreeze(
    program_id: &Pubkey,
    owner: &Pubkey,
    config: &Pubkey,
) -> Result<Instruction, ProgramError> {
    let init_data = TeleportInstruction::Unfreeze {};
    let data = init_data.try_to_vec()?;
    let accounts = vec![
        AccountMeta::new(*owner, true),
        AccountMeta::new(*config, false),
    ];
    Ok(Instruction {
        program_id: *program_id,
        accounts,
        data,
    })
}

// TODO
// pub fn teleport_in()
// pub fn teleport_out()