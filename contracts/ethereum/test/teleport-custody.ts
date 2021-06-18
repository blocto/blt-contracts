import { ethers } from "hardhat";
import { Signer, Contract } from "ethers";
import { solidity } from "ethereum-waffle";
import { use, expect } from "chai";

use(solidity);

describe("Teleport Custody", function () {
  let accounts: Signer[];
  let token: Contract;
  let teleportCustody: Contract;

  beforeEach(async function () {
    accounts = await ethers.getSigners();

    const Token = await ethers.getContractFactory("Token");
    token = await Token.deploy("BloctoToken", "BLT");

    const TeleportCustody = await ethers.getContractFactory("TeleportCustody");
    teleportCustody = await TeleportCustody.deploy(token.address);
  });

  it("freeze by owner", async function () {
    await teleportCustody.connect(accounts[0]).freeze();
    expect(await teleportCustody.isFrozen()).true;
  });

  it("freeze by other", async function () {
    expect(teleportCustody.connect(accounts[1]).freeze()).to.be.reverted;
  });

  it("unfreeze by owner", async function () {
    await teleportCustody.connect(accounts[0]).freeze();
    await teleportCustody.connect(accounts[0]).unfreeze();
    expect(await teleportCustody.isFrozen()).false;
  });

  it("unfreeze by other", async function () {
    expect(teleportCustody.connect(accounts[1]).unfreeze()).to.be.reverted;
  });

  it("get token", async function () {
    expect(await teleportCustody.getToken()).to.equal(token.address);
  });

  it("deposit allowance by other", async function () {
    expect(teleportCustody.connect(accounts[1]).depositAllowance(accounts[1].getAddress(), 100)).to.be.reverted;
  });

  it("deposit allowance by owner", async function () {
    // deposit allowance
    await expect(teleportCustody.connect(accounts[0]).depositAllowance(accounts[1].getAddress(), 100))
      .to.emit(teleportCustody, "AdminUpdated")
      .withArgs(await accounts[1].getAddress(), 100);

    // check it
    expect(await teleportCustody.allowedAmount(accounts[1].getAddress())).to.equal(100);
  });

  it("deposit allowance twice", async function () {
    // deposit allowance 1
    await expect(teleportCustody.connect(accounts[0]).depositAllowance(accounts[1].getAddress(), 100))
      .to.emit(teleportCustody, "AdminUpdated")
      .withArgs(await accounts[1].getAddress(), 100);

    // deposit allowance 2
    await expect(teleportCustody.connect(accounts[0]).depositAllowance(accounts[1].getAddress(), 100))
      .to.emit(teleportCustody, "AdminUpdated")
      .withArgs(await accounts[1].getAddress(), 100);

    // check it
    expect(await teleportCustody.allowedAmount(accounts[1].getAddress())).to.equal(200);
  });
});
