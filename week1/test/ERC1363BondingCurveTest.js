const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("ERC1363BondingCurve", function () {
  let bondingCurveToken;
  let owner, signer, userA, userB;

  describe("constructor", async function () {});

  describe("mintBondingCurve", async function () {
    beforeEach(async function () {
      [owner, userA, userB] = await ethers.getSigners();
      const BondingCurveToken = await ethers.getContractFactory(
        "ERC1363BondingCurve"
      );
      bondingCurveToken = await BondingCurveToken.deploy(
        "BondingCurveToken",
        "BCT"
      );
      bondingCurveTokenUserA = bondingCurveToken.connect(userA);
      await bondingCurveToken.deployed();
    });

    it("succeeds minting a small number of tokens", async function () {
      const count = ethers.utils.parseEther("0.000001");
      expect(await bondingCurveToken.getCurrentPrice()).to.be.equal(0);
      const currentPrice = await bondingCurveToken.getCurrentPrice();

      const PRICE_INCREASE_PER_TOKEN =
        await bondingCurveToken.PRICE_INCREASE_PER_TOKEN();
      const decimals = ethers.utils.parseEther("1");
      const endingPrice = currentPrice.add(
        PRICE_INCREASE_PER_TOKEN.mul(count).div(decimals)
      );
      const amountToPay = currentPrice
        .add(endingPrice)
        .mul(count)
        .div(decimals)
        .div(2);

      await bondingCurveTokenUserA.mintBondingCurve(count, {
        value: amountToPay,
      });

      expect(await bondingCurveToken.getCurrentPrice()).to.be.equal(
        endingPrice
      );
      expect(await bondingCurveToken.balanceOf(userA.address)).to.be.equal(
        count
      );

      expect(
        await bondingCurveToken.provider.getBalance(bondingCurveToken.address)
      ).to.be.equal(amountToPay);
    });

    it("succeeds minting 2 tokens", async function () {
      const count = ethers.utils.parseEther("2");
      expect(await bondingCurveToken.getCurrentPrice()).to.be.equal(0);
      const currentPrice = await bondingCurveToken.getCurrentPrice();

      const PRICE_INCREASE_PER_TOKEN =
        await bondingCurveToken.PRICE_INCREASE_PER_TOKEN();
      const decimals = ethers.utils.parseEther("1");
      const endingPrice = currentPrice.add(
        PRICE_INCREASE_PER_TOKEN.mul(count).div(decimals)
      );
      const amountToPay = currentPrice
        .add(endingPrice)
        .mul(count)
        .div(decimals)
        .div(2);

      await bondingCurveTokenUserA.mintBondingCurve(count, {
        value: amountToPay,
      });

      expect(await bondingCurveToken.getCurrentPrice()).to.be.equal(
        endingPrice
      );
      expect(await bondingCurveToken.balanceOf(userA.address)).to.be.equal(
        count
      );

      expect(
        await bondingCurveToken.provider.getBalance(bondingCurveToken.address)
      ).to.be.equal(amountToPay);
    });

    it("succeeds minting 5 tokens", async function () {
      const count = ethers.utils.parseEther("5");
      expect(await bondingCurveToken.getCurrentPrice()).to.be.equal(0);
      const currentPrice = await bondingCurveToken.getCurrentPrice();

      const PRICE_INCREASE_PER_TOKEN =
        await bondingCurveToken.PRICE_INCREASE_PER_TOKEN();
      const decimals = ethers.utils.parseEther("1");
      const endingPrice = currentPrice.add(
        PRICE_INCREASE_PER_TOKEN.mul(count).div(decimals)
      );
      const amountToPay = currentPrice
        .add(endingPrice)
        .mul(count)
        .div(decimals)
        .div(2);

      await bondingCurveTokenUserA.mintBondingCurve(count, {
        value: amountToPay,
      });

      expect(await bondingCurveToken.getCurrentPrice()).to.be.equal(
        endingPrice
      );
      expect(await bondingCurveToken.balanceOf(userA.address)).to.be.equal(
        count
      );

      expect(
        await bondingCurveToken.provider.getBalance(bondingCurveToken.address)
      ).to.be.equal(amountToPay);
    });

    it("minting and buying back refunds same amount", async function () {
      const count = ethers.utils.parseEther("5");
      expect(await bondingCurveToken.getCurrentPrice()).to.be.equal(0);
      const currentPrice = await bondingCurveToken.getCurrentPrice();

      const PRICE_INCREASE_PER_TOKEN =
        await bondingCurveToken.PRICE_INCREASE_PER_TOKEN();
      const decimals = ethers.utils.parseEther("1");
      const endingPrice = currentPrice.add(
        PRICE_INCREASE_PER_TOKEN.mul(count).div(decimals)
      );
      const amountToPay = currentPrice
        .add(endingPrice)
        .mul(count)
        .div(decimals)
        .div(2);

      await bondingCurveTokenUserA.mintBondingCurve(count, {
        value: amountToPay,
      });

      expect(await bondingCurveToken.getCurrentPrice()).to.be.equal(
        endingPrice
      );
      expect(await bondingCurveToken.balanceOf(userA.address)).to.be.equal(
        count
      );

      expect(
        await bondingCurveToken.provider.getBalance(bondingCurveToken.address)
      ).to.be.equal(amountToPay);

      const userABalanceBefore = await bondingCurveToken.provider.getBalance(
        userA.address
      );

      const tx = await bondingCurveTokenUserA[
        "transferAndCall(address,uint256)"
      ](bondingCurveToken.address, count);

      const receipt = await tx.wait();

      const gasUsed = receipt.cumulativeGasUsed.mul(receipt.effectiveGasPrice);

      const userABalanceAfter = await bondingCurveToken.provider.getBalance(
        userA.address
      );

      expect(
        userABalanceAfter.add(gasUsed).sub(userABalanceBefore)
      ).to.be.equal(amountToPay);

      expect(await bondingCurveToken.getCurrentPrice()).to.be.equal(0);
      expect(await bondingCurveToken.balanceOf(userA.address)).to.be.equal(0);
      expect(
        await bondingCurveToken.balanceOf(bondingCurveToken.address)
      ).to.be.equal(0);
      expect(
        await bondingCurveToken.provider.getBalance(bondingCurveToken.address)
      ).to.be.equal(0);
    });
  });
});
