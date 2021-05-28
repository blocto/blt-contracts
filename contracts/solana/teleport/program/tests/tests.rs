#![cfg(feature = "test-bpf")]

use {
    blt_teleport::error::TeleportError,
    borsh::de::BorshDeserialize,
    solana_program::{
        hash::Hash, instruction::InstructionError, pubkey::Pubkey, system_instruction,
    },
    solana_program_test::*,
    solana_sdk::{
        signature::{Keypair, Signer},
        transaction::{Transaction, TransactionError},
    },
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

async fn create_config(
    banks_client: &mut BanksClient,
    payer: &Keypair,
    recent_blockhash: &Hash,
    admin_keys: &[Pubkey],
) -> Pubkey {
    let owner_account = get_owner();
    let config_account = Keypair::new();
    let rent = banks_client.get_rent().await.unwrap();
    let config_account_len = blt_teleport::state::Config::LEN;
    let account_rent = rent.minimum_balance(config_account_len);

    let mut instructions = vec![
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
    ];

    for admin_key in admin_keys {
        instructions.push(
            blt_teleport::instruction::add_admin(
                &blt_teleport::id(),
                &owner_account.pubkey(),
                &config_account.pubkey(),
                &admin_key,
            )
            .unwrap(),
        )
    }

    let mut transaction = Transaction::new_with_payer(&instructions[..], Some(&payer.pubkey()));
    transaction.sign(
        &[&payer, &owner_account, &config_account],
        *recent_blockhash,
    );

    banks_client.process_transaction(transaction).await.unwrap();

    config_account.pubkey()
}

async fn get_config(
    banks_client: &mut BanksClient,
    config_pubkey: &Pubkey,
) -> blt_teleport::state::Config {
    let config_account = banks_client
        .get_account(*config_pubkey)
        .await
        .unwrap()
        .unwrap();
    blt_teleport::state::Config::try_from_slice(config_account.data.as_slice()).unwrap()
}

fn expected_admins(keys: &[Pubkey]) -> Vec<Pubkey> {
    let mut expected_admins = vec![Pubkey::default(); blt_teleport::state::MAX_ADMIN];

    let mut idx = 0;
    for key in keys {
        expected_admins[idx] = *key;
        idx += 1;
    }

    expected_admins
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

    let config_pubkey = create_config(&mut banks_client, &payer, &recent_blockhash, &[]).await;

    let config = get_config(&mut banks_client, &config_pubkey).await;

    assert_eq!(config.is_init, true)
}

#[tokio::test]
async fn test_add_admin() {
    let (mut banks_client, payer, recent_blockhash) = program_test().start().await;

    let admin_keys = &[Keypair::new().pubkey(), Keypair::new().pubkey()];
    let config_pubkey =
        create_config(&mut banks_client, &payer, &recent_blockhash, admin_keys).await;

    let config = get_config(&mut banks_client, &config_pubkey).await;

    assert_eq!(config.is_init, true);
    assert_eq!(config.admins, expected_admins(admin_keys)[..]);
}

#[tokio::test]
async fn test_add_admin_over_limit() {
    let (mut banks_client, payer, recent_blockhash) = program_test().start().await;

    let limit = blt_teleport::state::MAX_ADMIN;
    let mut admin_keys = Vec::with_capacity(limit);
    for _ in 0..limit {
        admin_keys.push(Keypair::new().pubkey());
    }
    let config_pubkey = create_config(
        &mut banks_client,
        &payer,
        &recent_blockhash,
        &admin_keys[..],
    )
    .await;

    let owner = get_owner();
    let mut transaction = Transaction::new_with_payer(
        &[blt_teleport::instruction::add_admin(
            &blt_teleport::id(),
            &owner.pubkey(),
            &config_pubkey,
            &Keypair::new().pubkey(),
        )
        .unwrap()],
        Some(&payer.pubkey()),
    );
    transaction.sign(&[&payer, &owner], recent_blockhash);
    let error = banks_client
        .process_transaction(transaction)
        .await
        .err()
        .unwrap()
        .unwrap();

    match error {
        TransactionError::InstructionError(_, InstructionError::Custom(error_index)) => {
            let program_error = TeleportError::UnexpectedError as u32;
            assert_eq!(error_index, program_error);
        }
        _ => panic!("Wrong error occurs while decreasing with wrong owner"),
    }
}

#[tokio::test]
async fn test_remove_admin() {
    let (mut banks_client, payer, recent_blockhash) = program_test().start().await;

    let admin_keys = &[
        Keypair::new().pubkey(),
        Keypair::new().pubkey(),
        Keypair::new().pubkey(),
    ];
    let config_pubkey =
        create_config(&mut banks_client, &payer, &recent_blockhash, admin_keys).await;

    let owner = get_owner();
    let mut transaction = Transaction::new_with_payer(
        &[blt_teleport::instruction::remove_admin(
            &blt_teleport::id(),
            &owner.pubkey(),
            &config_pubkey,
            &admin_keys[1],
        )
        .unwrap()],
        Some(&payer.pubkey()),
    );
    transaction.sign(&[&payer, &owner], recent_blockhash);
    banks_client.process_transaction(transaction).await.unwrap();

    let config = get_config(&mut banks_client, &config_pubkey).await;
    assert_eq!(config.is_init, true);
    let mut keys = expected_admins(admin_keys);
    keys[1] = Pubkey::default();
    assert_eq!(config.admins, keys[..]);
}

#[tokio::test]
async fn test_remove_not_exist_admin() {
    let (mut banks_client, payer, recent_blockhash) = program_test().start().await;

    let admin_keys = &[
        Keypair::new().pubkey(),
        Keypair::new().pubkey(),
        Keypair::new().pubkey(),
    ];
    let config_pubkey =
        create_config(&mut banks_client, &payer, &recent_blockhash, admin_keys).await;

    let owner = get_owner();
    let mut transaction = Transaction::new_with_payer(
        &[blt_teleport::instruction::remove_admin(
            &blt_teleport::id(),
            &owner.pubkey(),
            &config_pubkey,
            &Keypair::new().pubkey(),
        )
        .unwrap()],
        Some(&payer.pubkey()),
    );
    transaction.sign(&[&payer, &owner], recent_blockhash);
    let error = banks_client
        .process_transaction(transaction)
        .await
        .err()
        .unwrap()
        .unwrap();

    match error {
        TransactionError::InstructionError(_, InstructionError::Custom(error_index)) => {
            let program_error = TeleportError::UnexpectedError as u32;
            assert_eq!(error_index, program_error);
        }
        _ => panic!("Wrong error occurs while decreasing with wrong owner"),
    }
}
