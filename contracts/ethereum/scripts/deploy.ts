import { ethers } from "hardhat";

async function main() {
  const Token = await ethers.getContractFactory("Token");
  const token = await Token.deploy("BloctoToken", "BLT", 8);
  await token.deployed();
  console.log(`token address: ${token.address}`);

  const TeleportCustody = await ethers.getContractFactory("TeleportCustody");
  const teleportCustody = await TeleportCustody.deploy(token.address);
  await teleportCustody.deployed();
  console.log(`teleport address: ${teleportCustody.address}`);

  const accounts = await ethers.getSigners();
  let tx = await token.connect(accounts[0]).grantRole(token.MINTER_ROLE(), teleportCustody.address);
  console.log(`add minter auth for teleport contract, txhash: ${tx.hash}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
