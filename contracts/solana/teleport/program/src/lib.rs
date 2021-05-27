pub mod error;
pub mod instruction;
pub mod processor;
pub mod state;

#[cfg(not(feature = "no-entrypoint"))]
mod entrypoint;

// Export current sdk types for downstream users building with a different sdk version
pub use solana_program;

// program id
solana_program::declare_id!("BLT2FgFauegpkQPXmT9dSKtHevX1dDNPgj4KtKFiDbPq");
