import { ethers } from "hardhat";
import { Signer, Contract } from "ethers";
import { solidity } from "ethereum-waffle";
import { use, expect } from "chai";

use(solidity);

describe("Token", function () {
  let accounts: Signer[];
  let token: Contract;

  beforeEach(async function () {
    accounts = await ethers.getSigners();
    const Token = await ethers.getContractFactory("Token");
    token = await Token.deploy("token", "BLT", 8);
  });

  it("init supply should be 0", async function () {
    expect(await token.totalSupply()).to.equal(0);
  });

  it("token decimals", async function () {
    expect(await token.decimals()).to.equal(8);
  });

  it("mint by owner", async function () {
    await expect(() => token.connect(accounts[0]).mint(accounts[1].getAddress(), 100)).to.changeTokenBalance(
      token,
      accounts[1],
      100
    );
  });

  it("mint by allowed role", async function () {
    await token.connect(accounts[0]).grantRole(token.MINTER_ROLE(), accounts[1].getAddress());
    await expect(() => token.connect(accounts[1]).mint(accounts[2].getAddress(), 100)).to.changeTokenBalance(
      token,
      accounts[2],
      100
    );
  });

  it("mint by unknown", async function () {
    await expect(token.connect(accounts[1]).mint(accounts[2].getAddress(), 100)).to.be.reverted;
  });

  it("burn by user", async function () {
    await token.connect(accounts[0]).mint(accounts[1].getAddress(), 100);
    await expect(() => token.connect(accounts[1]).burn(100)).to.changeTokenBalance(token, accounts[1], -100);
  });

  it("burn by owner", async function () {
    await token.connect(accounts[0]).mint(accounts[1].getAddress(), 100);
    await token.connect(accounts[1]).approve(accounts[0].getAddress(), 100);
    await expect(() => token.connect(accounts[0]).burnFrom(accounts[1].getAddress(), 100)).to.changeTokenBalance(
      token,
      accounts[1],
      -100
    );
  });
});
