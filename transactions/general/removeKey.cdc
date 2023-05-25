transaction(keyIndex: Int) {
  prepare(signer: AuthAccount) {
    // revoke old recovery key
		signer.keys.revoke(keyIndex: keyIndex)
  }
}
