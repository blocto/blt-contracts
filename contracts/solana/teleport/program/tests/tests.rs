#![cfg(feature = "test-bpf")]

use blt_teleport;
use borsh::de::BorshDeserialize;
use solana_program::{hash::Hash, program_pack::Pack, pubkey::Pubkey, system_instruction};
use solana_program_test::*;
use solana_sdk::{
    account::Account,
    signature::{Keypair, Signer},
    transaction::Transaction,
    transport::TransportError,
};

pub fn program_test() -> ProgramTest {
    ProgramTest::new(
        "blt_teleport",
        blt_teleport::id(),
        processor!(blt_teleport::processor::Processor::process_instruction),
    )
}

#[tokio::test]
async fn test_get_owner() {
    let (mut banks_client, payer, recent_blockhash) = program_test().start().await;
    let mut transaction = Transaction::new_with_payer(
        &[blt_teleport::instruction::get_owner(&blt_teleport::id()).unwrap()],
        Some(&payer.pubkey()),
    );
    transaction.sign(&[&payer], recent_blockhash);

    banks_client.process_transaction(transaction).await.unwrap();
}
