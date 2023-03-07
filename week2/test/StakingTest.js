const { ethers } = require("hardhat");
const { expect } = require("chai");
const { solidityKeccak256 } = require("ethers/lib/utils");
const {
  createPresaleMerkleBitmap,
  createPresaleMerkleMapping,
} = require("./utils.js");

describe("Staking", function () {
  let erc721, erc20, staking;
  let owner, signer, userA, userB;

  beforeEach(async function () {
    [owner, signer, userA, userB] = await ethers.getSigners();
    const ERC721 = await ethers.getContractFactory("ERC721Staking");
    const ERC20 = await ethers.getContractFactory("ERC20Staking");
    const Staking = await ethers.getContractFactory("StakingContract");
    staking = await Staking.deploy();
    erc721 = await ERC721.deploy("TestContract", "TC");
    erc20 = await ERC20.deploy("TestContract", "TC", staking.address);
    erc20UserA = erc20.connect(userA);
    erc721UserA = erc721.connect(userA);
    erc721UserB = erc721.connect(userB);
    stakingUserA = staking.connect(userA);
    stakingUserB = staking.connect(userB);
    await Promise.all([
      erc721.deployed(),
      erc20.deployed(),
      staking.deployed(),
    ]);
  });

  describe("StakingContract", async function () {
    it("succeeds staking and withdrawing tokens", async function () {
      const setMintAddressTx = await erc20.setMintAddress(staking.address);
      await setMintAddressTx.wait();
      const setERC20ContractTx = await staking.setERC20Contract(erc20.address);
      await setERC20ContractTx.wait();
      const setERC721ContractTx = await staking.setERC721Contract(
        erc721.address
      );
      await setERC721ContractTx.wait();

      const publicMintTx = await erc721UserA.publicMint(1, {
        value: ethers.utils.parseEther("0.01"),
      });
      await publicMintTx.wait();

      const xferTx = await erc721UserA[
        "safeTransferFrom(address,address,uint256)"
      ](userA.address, staking.address, 0);
      await xferTx.wait();
      const claimTokensTx = await stakingUserA.claimTokens(0);
      await claimTokensTx.wait();
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

    it("fails when not owner calls setERC20Contract", async function () {
      await expect(
        stakingUserA.setERC20Contract(erc20.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("fails when not owner calls setERC721Contract", async function () {
      await expect(
        stakingUserA.setERC721Contract(erc721.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("fails when not owner calls withdrawNFT", async function () {
      const setMintAddressTx = await erc20.setMintAddress(staking.address);
      await setMintAddressTx.wait();
      const setERC20ContractTx = await staking.setERC20Contract(erc20.address);
      await setERC20ContractTx.wait();
      const setERC721ContractTx = await staking.setERC721Contract(
        erc721.address
      );
      await setERC721ContractTx.wait();

      const publicMintTx = await erc721UserA.publicMint(1, {
        value: ethers.utils.parseEther("0.01"),
      });
      await publicMintTx.wait();

      const xferTx = await erc721UserA[
        "safeTransferFrom(address,address,uint256)"
      ](userA.address, staking.address, 0);
      await xferTx.wait();

      await expect(stakingUserB.withdrawNFT(0)).to.be.revertedWith(
        "Only owner can withdraw"
      );
    });

    it("fails when not owner calls claimTokens", async function () {
      const setMintAddressTx = await erc20.setMintAddress(staking.address);
      await setMintAddressTx.wait();
      const setERC20ContractTx = await staking.setERC20Contract(erc20.address);
      await setERC20ContractTx.wait();
      const setERC721ContractTx = await staking.setERC721Contract(
        erc721.address
      );
      await setERC721ContractTx.wait();

      const publicMintTx = await erc721UserA.publicMint(1, {
        value: ethers.utils.parseEther("0.01"),
      });
      await publicMintTx.wait();

      const xferTx = await erc721UserA[
        "safeTransferFrom(address,address,uint256)"
      ](userA.address, staking.address, 0);
      await xferTx.wait();

      await expect(stakingUserB.claimTokens(0)).to.be.revertedWith(
        "Only owner can claim"
      );
    });
  });

  describe("ERC20Staking", async function () {
    it("fails when not owner calls setMintAddress", async function () {
      await expect(
        erc20UserA.setMintAddress(staking.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("fails when not mint address calls mint", async function () {
      await expect(erc20UserA.mint(userA.address, 1)).to.be.revertedWith(
        "Only mint address can mint"
      );
    });
  });

  describe("ERC721Staking", async function () {
    it("succeeds when owner calls setBaseURI", async function () {
      expect(await erc721.baseTokenURI()).to.equal(
        "ipfs://bafybeih5lgrstt7kredzhpcvmft2qefue5pl3ykrdktadw5w62zd7cbkja/"
      );
      const setBaseURITx = await erc721.setBaseURI("https://test.com/");
      await setBaseURITx.wait();
      expect(await erc721.baseTokenURI()).to.equal("https://test.com/");
    });

    it("fails when not owner calls setBaseURI", async function () {
      await expect(
        erc721UserA.setBaseURI("https://test.com/")
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("succeeds when user calls publicMint correctly", async function () {
      const publicMintTx = await erc721UserA.publicMint(2, {
        value: ethers.utils.parseEther("0.02"),
      });
      await publicMintTx.wait();
      expect(await erc721UserA.balanceOf(userA.address)).to.equal(2);
    });

    it("fails when user calls publicMint with too little payment", async function () {
      await expect(
        erc721UserA.publicMint(2, {
          value: ethers.utils.parseEther("0.01"),
        })
      ).to.be.revertedWith("INVALID_PRICE");
    });

    it("fails when user calls publicMint with too many mints", async function () {
      await expect(
        erc721UserA.publicMint(1001, {
          value: ethers.utils.parseEther("10.01"),
        })
      ).to.be.revertedWith("MINT_TOO_LARGE");
    });

    it("succeeds when owner calls withdraw", async function () {
      await erc721UserA.publicMint(1000, {
        value: ethers.utils.parseEther("10"),
      });
      const beginningBalance = await erc721.provider.getBalance(owner.address);
      const withdrawTx = await erc721.withdraw();
      const receipt = await withdrawTx.wait();
      const gasUsed = receipt.cumulativeGasUsed.mul(receipt.effectiveGasPrice);
      expect(await erc721.provider.getBalance(owner.address)).to.be.equal(
        beginningBalance.sub(gasUsed).add(ethers.utils.parseEther("10"))
      );
    });

    it("fails when not owner calls withdraw", async function () {
      await expect(erc721UserA.withdraw()).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });

    it("successfully fetches the right tokenURI", async function () {
      const publicMintTx = await erc721UserA.publicMint(2, {
        value: ethers.utils.parseEther("0.02"),
      });
      await publicMintTx.wait();
      expect(await erc721UserA.tokenURI(0)).to.be.equal(
        "ipfs://bafybeih5lgrstt7kredzhpcvmft2qefue5pl3ykrdktadw5w62zd7cbkja/0"
      );
    });

    it("transferOwnership and renounceOwnership succeed when owner calls", async function () {
      const xferOwnershipTx = await erc721.transferOwnership(userA.address);
      await xferOwnershipTx.wait();
      expect(await erc721.owner()).to.be.equal(userA.address);
      const renounceOwnershipTx = await erc721UserA.renounceOwnership();
      await renounceOwnershipTx.wait();
      expect(await erc721.owner()).to.be.equal(
        "0x0000000000000000000000000000000000000000"
      );
    });
  });
});
