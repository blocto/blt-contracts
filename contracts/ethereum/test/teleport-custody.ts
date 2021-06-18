import { ethers } from "hardhat";
import { Signer, Contract } from "ethers";
import { solidity } from "ethereum-waffle";
import { use, expect } from "chai";

use(solidity);

describe("Teleport Custody", function () {
  let accounts: Signer[];
  let teleportCustody: Contract;

  beforeEach(async function () {
    accounts = await ethers.getSigners();

    const TeleportCustody = await ethers.getContractFactory("TeleportCustody");
    teleportCustody = await TeleportCustody.deploy();
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
});
