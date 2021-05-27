#![cfg(feature = "test-bpf")]

use blt_teleport::error::TeleportError;
use borsh::de::BorshDeserialize;
use solana_program::{
    hash::Hash, instruction::InstructionError, program_pack::Pack, pubkey::Pubkey,
    system_instruction,
};
use solana_program_test::*;
use solana_sdk::{
    account::Account,
    signature::{Keypair, Signer},
    transaction::{Transaction, TransactionError},
    transport::TransportError,
};

pub fn program_test() -> ProgramTest {
    ProgramTest::new(
        "blt_teleport",
        blt_teleport::id(),
        processor!(blt_teleport::processor::Processor::process_instruction),
    )
}

pub fn get_owner() -> Keypair {
    Keypair::from_bytes(&[
        216, 77, 18, 252, 166, 244, 245, 106, 13, 111, 107, 26, 108, 43, 230, 245, 113, 207, 205,
        116, 14, 52, 64, 196, 192, 63, 41, 220, 146, 82, 66, 53, 161, 111, 219, 59, 147, 221, 7,
        127, 88, 42, 141, 30, 211, 69, 198, 108, 142, 249, 183, 249, 92, 127, 241, 91, 118, 190,
        46, 20, 186, 220, 132, 23,
    ])
    .unwrap()
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

#[tokio::test]
async fn test_init_config_with_fake_owner() {
    let (mut banks_client, payer, recent_blockhash) = program_test().start().await;

    let fake_owner = Keypair::new();
    let config_account = Keypair::new();
    let rent = banks_client.get_rent().await.unwrap();
    let config_account_len = blt_teleport::state::Config::LEN;
    let account_rent = rent.minimum_balance(config_account_len);

    let mut transaction = Transaction::new_with_payer(
        &[
            system_instruction::create_account(
                &payer.pubkey(),
                &config_account.pubkey(),
                account_rent,
                config_account_len as u64,
                &blt_teleport::id(),
            ),
            blt_teleport::instruction::init_config(
                &blt_teleport::id(),
                &fake_owner.pubkey(),
                &config_account.pubkey(),
            )
            .unwrap(),
        ],
        Some(&payer.pubkey()),
    );
    transaction.sign(&[&payer, &fake_owner, &config_account], recent_blockhash);

    let error = banks_client
        .process_transaction(transaction)
        .await
        .err()
        .unwrap()
        .unwrap();

    match error {
        TransactionError::InstructionError(_, InstructionError::Custom(error_index)) => {
            let program_error = TeleportError::AuthFailed as u32;
            assert_eq!(error_index, program_error);
        }
        _ => panic!("Wrong error occurs while decreasing with wrong owner"),
    }
}

#[tokio::test]
async fn test_init_config() {
    let (mut banks_client, payer, recent_blockhash) = program_test().start().await;

    let owner_account = get_owner();
    let config_account = Keypair::new();
    let rent = banks_client.get_rent().await.unwrap();
    let config_account_len = blt_teleport::state::Config::LEN;
    let account_rent = rent.minimum_balance(config_account_len);

    let mut transaction = Transaction::new_with_payer(
        &[
            system_instruction::create_account(
                &payer.pubkey(),
                &config_account.pubkey(),
                account_rent,
                config_account_len as u64,
                &blt_teleport::id(),
            ),
            blt_teleport::instruction::init_config(
                &blt_teleport::id(),
                &owner_account.pubkey(),
                &config_account.pubkey(),
            )
            .unwrap(),
        ],
        Some(&payer.pubkey()),
    );
    transaction.sign(&[&payer, &owner_account, &config_account], recent_blockhash);

    banks_client.process_transaction(transaction).await.unwrap();

    let config_account = banks_client
        .get_account(config_account.pubkey())
        .await
        .unwrap()
        .unwrap();
    let config_account =
        blt_teleport::state::Config::try_from_slice(config_account.data.as_slice()).unwrap();
    assert_eq!(config_account.is_init, true)
}
