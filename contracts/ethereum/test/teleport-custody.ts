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

  it("teleport out by others", async function () {
    expect(
      teleportCustody
        .connect(accounts[1])
        .teleportOut(100, accounts[2].getAddress(), ethers.utils.formatBytes32String("flowTxHash"))
    ).to.be.reverted;
  });

  it("teleport out by teleport admin", async function () {
    // setup
    await teleportCustody.connect(accounts[0]).depositAllowance(accounts[1].getAddress(), 100);
    await token.connect(accounts[0]).grantRole(token.MINTER_ROLE(), teleportCustody.address);

    // teleport out
    await expect(
      teleportCustody
        .connect(accounts[1])
        .teleportOut(50, accounts[2].getAddress(), ethers.utils.formatBytes32String("flowTxHash"))
    )
      .to.emit(teleportCustody, "AdminUpdated")
      .withArgs(await accounts[1].getAddress(), 50)
      .to.emit(teleportCustody, "TeleportOut")
      .withArgs(50, await accounts[2].getAddress(), ethers.utils.formatBytes32String("flowTxHash"));

    // check token balance
    expect(await token.balanceOf(accounts[2].getAddress())).to.equal(50);

    // check admin allowance
    expect(await teleportCustody.allowedAmount(accounts[1].getAddress())).to.equal(50);
  });

  it("teleport out by same tx hash", async function () {
    // setup
    await teleportCustody.connect(accounts[0]).depositAllowance(accounts[1].getAddress(), 100);
    await token.connect(accounts[0]).grantRole(token.MINTER_ROLE(), teleportCustody.address);

    // teleport out 1
    await teleportCustody
      .connect(accounts[1])
      .teleportOut(50, accounts[2].getAddress(), ethers.utils.formatBytes32String("flowTxHash"));

    // teleport out 2
    expect(
      teleportCustody
        .connect(accounts[1])
        .teleportOut(50, accounts[2].getAddress(), ethers.utils.formatBytes32String("flowTxHash"))
    ).to.be.reverted;
  });

  it("teleport out over admin's allowance", async function () {
    // setup
    await teleportCustody.connect(accounts[0]).depositAllowance(accounts[1].getAddress(), 100);
    await token.connect(accounts[0]).grantRole(token.MINTER_ROLE(), teleportCustody.address);

    // teleport out 1
    await teleportCustody
      .connect(accounts[1])
      .teleportOut(100, accounts[2].getAddress(), ethers.utils.formatBytes32String("flowTxHash"));

    // teleport out 2
    expect(
      teleportCustody
        .connect(accounts[1])
        .teleportOut(50, accounts[2].getAddress(), ethers.utils.formatBytes32String("flowTxHash2"))
    ).to.be.reverted;
  });

  it("teleport out when is frozen", async function () {
    // setup
    await teleportCustody.connect(accounts[0]).depositAllowance(accounts[1].getAddress(), 100);
    await token.connect(accounts[0]).grantRole(token.MINTER_ROLE(), teleportCustody.address);
    await teleportCustody.connect(accounts[0]).freeze();

    // teleport out
    expect(
      teleportCustody
        .connect(accounts[1])
        .teleportOut(100, accounts[2].getAddress(), ethers.utils.formatBytes32String("flowTxHash"))
    ).to.be.reverted;
  });
});
