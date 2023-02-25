const { ethers } = require("hardhat");
const { expect } = require("chai");
const { solidityKeccak256 } = require("ethers/lib/utils");
const {
  createPresaleMerkleBitmap,
  createPresaleMerkleMapping,
} = require("./utils.js");

describe("StakingContract", function () {
  let erc721, erc20, staking;
  let owner, signer, userA, userB;

  describe("constructor", async function () {});

  describe("presale mint", async function () {
    beforeEach(async function () {
      [owner, signer, userA, userB, userC] = await ethers.getSigners();
      const ERC721 = await ethers.getContractFactory("ERC721Staking");
      const ERC20 = await ethers.getContractFactory("ERC20Staking");
      const Staking = await ethers.getContractFactory("StakingContract");
      staking = await Staking.deploy();
      erc721 = await ERC721.deploy("TestContract", "TC");
      erc20 = await ERC20.deploy("TestContract", "TC", staking.address);
      erc721UserA = erc721.connect(userA);
      stakingUserA = staking.connect(userA);
      await Promise.all([
        erc721.deployed(),
        erc20.deployed(),
        staking.deployed(),
      ]);
    });

    it("succeeds staking and withdrawing tokens", async function () {
      await erc20.setMintAddress(staking.address);
      await staking.setERC20Contract(erc20.address);
      await staking.setERC721Contract(erc721.address);

      await erc721UserA.publicMint(1, {
        value: ethers.utils.parseEther("0.01"),
      });

      await erc721UserA["safeTransferFrom(address,address,uint256)"](
        userA.address,
        staking.address,
        0
      );
      await stakingUserA.claimTokens(0);
      // not guaranteed, but practically speaking 1 second passes here reliably
      expect(await erc20.balanceOf(userA.address)).to.be.equal(
        ethers.utils.parseEther("1").mul(10).div(86400)
      );
      expect(await erc721.balanceOf(userA.address)).to.be.equal(0);
      await stakingUserA.withdrawNFT(0);
      // two seconds pass here, so we get 2 seconds worth of tokens
      expect(await erc20.balanceOf(userA.address)).to.be.equal(
        ethers.utils.parseEther("1").mul(10).div(86400).mul(2)
      );
      expect(await erc721.balanceOf(userA.address)).to.be.equal(1);
    });
  });
});
