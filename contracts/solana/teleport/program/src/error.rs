//! Error types

use {
    num_derive::FromPrimitive,
    num_traits::FromPrimitive,
    solana_program::{
        decode_error::DecodeError, msg, program_error::PrintProgramError,
        program_error::ProgramError,
    },
    thiserror::Error,
};

#[derive(Clone, Debug, Eq, Error, FromPrimitive, PartialEq)]
pub enum TeleportError {
    #[error("AuthFailed")]
    AuthFailed,
    #[error("UninitializedAccount")]
    UninitializedAccount,
    #[error("AlreadyInUse")]
    AlreadyInUse,
    #[error("NotRentExempt")]
    NotRentExempt,
    #[error("MissingRequiredSignature")]
    MissingRequiredSignature,
    #[error("IncorrectProgramAccount")]
    IncorrectProgramAccount,
    #[error("Freeze")]
    Freeze,
    #[error("UnexpectedError")]
    UnexpectedError,
}

impl From<TeleportError> for ProgramError {
    fn from(e: TeleportError) -> Self {
        ProgramError::Custom(e as u32)
    }
}

impl<T> DecodeError<T> for TeleportError {
    fn type_of() -> &'static str {
        "Teleport Error"
    }
}

impl PrintProgramError for TeleportError {
    fn print<E>(&self)
    where
        E: 'static + std::error::Error + DecodeError<E> + PrintProgramError + FromPrimitive,
    {
        match self {
            TeleportError::AuthFailed => msg!("Auth Failed"),
            TeleportError::UninitializedAccount => msg!("Uninitialized Account"),
            TeleportError::AlreadyInUse => msg!("Already In Use"),
            TeleportError::NotRentExempt => msg!("Not Rent Exempt"),
            TeleportError::MissingRequiredSignature => msg!("Missing Required Signature"),
            TeleportError::IncorrectProgramAccount => msg!("Incorrect Program Account"),
            TeleportError::Freeze => msg!("Freeze"),
            TeleportError::UnexpectedError => msg!("Unexpected Error"),
        }
    }
}
