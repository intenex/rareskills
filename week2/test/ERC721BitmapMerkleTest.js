const { ethers } = require("hardhat");
const { expect } = require("chai");
const { solidityKeccak256 } = require("ethers/lib/utils");
const { createPresaleMerkle } = require("./utils.js");

describe("BitmapMerkleTreeERC721", function () {
  let erc721;
  let owner, signer, userA, userB;

  describe("constructor", async function () {});

  describe("presale mint", async function () {
    beforeEach(async function () {
      [owner, signer, userA, userB, userC] = await ethers.getSigners();
      const BitmapMerkleTreeERC721 = await ethers.getContractFactory(
        "BitmapMerkleTreeERC721"
      );
      presaleList = [
        { bitmapNumber: 1, address: userA.address },
        { bitmapNumber: 777, address: userB.address },
      ];

      presaleMerkleTree = await createPresaleMerkle(presaleList);
      presaleMerkleTreeRoot = presaleMerkleTree.getHexRoot();
      erc721 = await BitmapMerkleTreeERC721.deploy("TestContract", "TC");
      erc721UserA = erc721.connect(userA);
      erc721UserB = erc721.connect(userB);
      await erc721.deployed();
    });

    it("succeeds minting a token", async function () {
      const bitmapNumber = 1;
      const address = userA.address;
      const proof = presaleMerkleTree.getHexProof(
        solidityKeccak256(["uint256", "address"], [bitmapNumber, address])
      );

      await erc721UserA.presaleMintBitmap(bitmapNumber, proof, {
        value: ethers.utils.parseEther("0.01"),
      });
      expect(await erc721.balanceOf(userA.address)).to.be.equal(1);
    });
  });
});
