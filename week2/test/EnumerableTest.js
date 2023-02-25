const { ethers } = require("hardhat");
const { expect } = require("chai");
const { solidityKeccak256 } = require("ethers/lib/utils");
const {
  createPresaleMerkleBitmap,
  createPresaleMerkleMapping,
} = require("./utils.js");

describe("StakingContract", function () {
  let erc721enumerable, tracker;
  let owner, signer, userA;

  describe("constructor", async function () {});

  describe("prime enumeration", async function () {
    beforeEach(async function () {
      [owner, signer, userA] = await ethers.getSigners();
      const ERC721Enumerable = await ethers.getContractFactory(
        "EnumerableERC721"
      );
      const Tracker = await ethers.getContractFactory("EnumerableTracker");
      erc721enumerable = await ERC721Enumerable.deploy("TestContract", "TC");
      tracker = await Tracker.deploy(erc721enumerable.address);
      await Promise.all([erc721enumerable.deployed(), tracker.deployed()]);
    });

    it("succeeds in returning the correct amount of prime token ids held by an address", async function () {
      expect(await tracker.primeTokenIdBalanceOf(userA.address)).to.be.equal(0);
      await erc721enumerable.gift([userA.address], 1);
      expect(await tracker.primeTokenIdBalanceOf(userA.address)).to.be.equal(0);
      await erc721enumerable.gift([userA.address], 2);
      expect(await tracker.primeTokenIdBalanceOf(userA.address)).to.be.equal(2);
      await erc721enumerable.gift([userA.address], 17);
      expect(await tracker.primeTokenIdBalanceOf(userA.address)).to.be.equal(8);
    });
  });
});
