transaction(key: String) {
  prepare(account: AuthAccount) {
    account.keys.add(
      publicKey: PublicKey(
          publicKey: key.decodeHex(),
          signatureAlgorithm: SignatureAlgorithm.ECDSA_secp256k1
      ),
      hashAlgorithm: HashAlgorithm.SHA2_256,
      weight: 1000.0
    )
  }
}
