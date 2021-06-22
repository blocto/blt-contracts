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

async fn create_admin(
    banks_client: &mut BanksClient,
    payer: &Keypair,
    recent_blockhash: &Hash,
    auth: &Pubkey,
    allowance: u64,
) -> Pubkey {
    let owner_account = get_owner();
    let admin_account = Keypair::new();
    let rent = banks_client.get_rent().await.unwrap();
    let admin_account_len = blt_teleport::state::Admin::LEN;
    let account_rent = rent.minimum_balance(admin_account_len);

    let instructions = vec![
        system_instruction::create_account(
            &payer.pubkey(),
            &admin_account.pubkey(),
            account_rent,
            admin_account_len as u64,
            &blt_teleport::id(),
        ),
        blt_teleport::instruction::init_admin(
            &blt_teleport::id(),
            &owner_account.pubkey(),
            &admin_account.pubkey(),
            auth,
            allowance,
        )
        .unwrap(),
    ];

    let mut transaction = Transaction::new_with_payer(&instructions[..], Some(&payer.pubkey()));
    transaction.sign(&[&payer, &owner_account, &admin_account], *recent_blockhash);

    banks_client.process_transaction(transaction).await.unwrap();

    admin_account.pubkey()
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

async fn get_admin(
    banks_client: &mut BanksClient,
    admin_pubkey: &Pubkey,
) -> blt_teleport::state::Admin {
    let admin_account = banks_client
        .get_account(*admin_pubkey)
        .await
        .unwrap()
        .unwrap();
    blt_teleport::state::Admin::try_from_slice(admin_account.data.as_slice()).unwrap()
}

async fn get_teleport_out_record(
    banks_client: &mut BanksClient,
    record: &Pubkey,
) -> blt_teleport::state::TeleportOutRecord {
    let record_account = banks_client.get_account(*record).await.unwrap().unwrap();
    blt_teleport::state::TeleportOutRecord::try_from_slice(record_account.data.as_slice()).unwrap()
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

    assert_eq!(config.is_init, true);
    assert_eq!(config.is_frozen, false);
}

#[tokio::test]
async fn test_init_admin() {
    let (mut banks_client, payer, recent_blockhash) = program_test().start().await;

    let auth = Pubkey::new_unique();
    let allowance = 1_000_000_000;
    let admin_pubkey = create_admin(
        &mut banks_client,
        &payer,
        &recent_blockhash,
        &auth,
        allowance,
    )
    .await;

    let admin = get_admin(&mut banks_client, &admin_pubkey).await;

    assert_eq!(admin.is_init, true);
    assert_eq!(admin.auth, auth);
    assert_eq!(admin.allowance, allowance);
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
async fn test_deposit_allowance() {
    let (mut banks_client, payer, recent_blockhash) = program_test().start().await;

    let auth = Pubkey::new_unique();
    let allowance = 1_000_000_000;
    let admin_pubkey = create_admin(
        &mut banks_client,
        &payer,
        &recent_blockhash,
        &auth,
        allowance,
    )
    .await;

    let deposit_num = 1;
    let owner = get_owner();
    let mut transaction = Transaction::new_with_payer(
        &[blt_teleport::instruction::deposit_allowance(
            &blt_teleport::id(),
            &owner.pubkey(),
            &admin_pubkey,
            deposit_num,
        )
        .unwrap()],
        Some(&payer.pubkey()),
    );
    transaction.sign(&[&payer, &owner], recent_blockhash);
    banks_client.process_transaction(transaction).await.unwrap();

    let admin = get_admin(&mut banks_client, &admin_pubkey).await;
    assert_eq!(admin.is_init, true);
    assert_eq!(admin.auth, auth);
    assert_eq!(admin.allowance, allowance + deposit_num);
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

#[tokio::test]
async fn test_freeze_and_unfreeze() {
    let (mut banks_client, payer, recent_blockhash) = program_test().start().await;

    let config_pubkey = create_config(&mut banks_client, &payer, &recent_blockhash, &[]).await;

    let owner = get_owner();
    let mut transaction = Transaction::new_with_payer(
        &[
            blt_teleport::instruction::freeze(&blt_teleport::id(), &owner.pubkey(), &config_pubkey)
                .unwrap(),
        ],
        Some(&payer.pubkey()),
    );
    transaction.sign(&[&payer, &owner], recent_blockhash);
    banks_client.process_transaction(transaction).await.unwrap();

    let config = get_config(&mut banks_client, &config_pubkey).await;
    assert_eq!(config.is_init, true);
    assert_eq!(config.is_frozen, true);

    let mut transaction = Transaction::new_with_payer(
        &[blt_teleport::instruction::unfreeze(
            &blt_teleport::id(),
            &owner.pubkey(),
            &config_pubkey,
        )
        .unwrap()],
        Some(&payer.pubkey()),
    );
    transaction.sign(&[&payer, &owner], recent_blockhash);
    banks_client.process_transaction(transaction).await.unwrap();

    let config = get_config(&mut banks_client, &config_pubkey).await;
    assert_eq!(config.is_init, true);
    assert_eq!(config.is_frozen, false);
}

#[tokio::test]
async fn test_inin_teleport_out_record() {
    let (mut banks_client, payer, recent_blockhash) = program_test().start().await;

    let rent = banks_client.get_rent().await.unwrap();
    let record_account_len = blt_teleport::state::TeleportOutRecord::LEN;
    let account_rent = rent.minimum_balance(record_account_len);

    let record = Keypair::new();

    let mut transaction = Transaction::new_with_payer(
        &[
            system_instruction::create_account(
                &payer.pubkey(),
                &record.pubkey(),
                account_rent,
                record_account_len as u64,
                &blt_teleport::id(),
            ),
            blt_teleport::instruction::init_teleport_out_record(
                &blt_teleport::id(),
                &record.pubkey(),
            )
            .unwrap(),
        ],
        Some(&payer.pubkey()),
    );
    transaction.sign(&[&payer, &record], recent_blockhash);
    banks_client.process_transaction(transaction).await.unwrap();

    let record = get_teleport_out_record(&mut banks_client, &record.pubkey()).await;
    assert_eq!(record.is_init, true);
}

async fn create_teleport_out_record(
    banks_client: &mut BanksClient,
    payer: &Keypair,
    recent_blockhash: &Hash,
) -> Pubkey {
    let rent = banks_client.get_rent().await.unwrap();
    let record_account_len = blt_teleport::state::TeleportOutRecord::LEN;
    let account_rent = rent.minimum_balance(record_account_len);

    let record = Keypair::new();

    let mut transaction = Transaction::new_with_payer(
        &[
            system_instruction::create_account(
                &payer.pubkey(),
                &record.pubkey(),
                account_rent,
                record_account_len as u64,
                &blt_teleport::id(),
            ),
            blt_teleport::instruction::init_teleport_out_record(
                &blt_teleport::id(),
                &record.pubkey(),
            )
            .unwrap(),
        ],
        Some(&payer.pubkey()),
    );
    transaction.sign(&[&payer, &record], *recent_blockhash);
    banks_client.process_transaction(transaction).await.unwrap();

    record.pubkey()
}

#[tokio::test]
async fn test_close_teleport_out_record() {
    let (mut banks_client, payer, recent_blockhash) = program_test().start().await;

    let auth = Keypair::new();
    let admin_pubkey = create_admin(
        &mut banks_client,
        &payer,
        &recent_blockhash,
        &auth.pubkey(),
        1000,
    )
    .await;

    let config_pubkey = create_config(
        &mut banks_client,
        &payer,
        &recent_blockhash,
        &[admin_pubkey],
    )
    .await;

    let record_pubkey =
        create_teleport_out_record(&mut banks_client, &payer, &recent_blockhash).await;

    let rent = banks_client.get_rent().await.unwrap();
    let record_account_len = blt_teleport::state::TeleportOutRecord::LEN;
    let account_rent = rent.minimum_balance(record_account_len);

    let mut transaction = Transaction::new_with_payer(
        &[blt_teleport::instruction::close_teleport_out_record(
            &blt_teleport::id(),
            &config_pubkey,
            &admin_pubkey,
            &auth.pubkey(),
            &record_pubkey,
            &auth.pubkey(),
        )
        .unwrap()],
        Some(&payer.pubkey()),
    );
    transaction.sign(&[&payer, &auth], recent_blockhash);
    banks_client.process_transaction(transaction).await.unwrap();

    assert_eq!(banks_client.get_balance(record_pubkey).await.unwrap(), 0);
    assert_eq!(banks_client.get_balance(auth.pubkey()).await.unwrap(), account_rent);
}
