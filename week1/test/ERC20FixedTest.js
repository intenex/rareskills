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
      await bondingCurveToken.deployed();
    });

    it("succeeds minting 100000 smallest units of account", async function () {
      const count = 100000;
      expect(await bondingCurveToken.getCurrentPrice()).to.be.equal(0);
      const currentPrice = await bondingCurveToken.getCurrentPrice();

      const PRICE_INCREASE_PER_TOKEN =
        await bondingCurveToken.PRICE_INCREASE_PER_TOKEN();
      const smallestUnitOfIncrease = PRICE_INCREASE_PER_TOKEN.div(
        ethers.utils.parseEther("0.0001")
      );
      const decimals = ethers.utils.parseEther("1");
      const endingPrice = currentPrice.add(
        PRICE_INCREASE_PER_TOKEN.mul(count).div(decimals)
      );
      const amountToPay = currentPrice
        .add(endingPrice)
        .add(smallestUnitOfIncrease)
        .mul(count)
        .div(2);
      console.log(`currentPrice`, ethers.utils.formatEther(currentPrice));
      console.log(`endingPrice`, ethers.utils.formatEther(endingPrice));
      console.log(`amountToPay`, ethers.utils.formatEther(amountToPay));

      await bondingCurveToken.connect(userA).mintBondingCurve(count, {
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

    // it("succeeds minting 2 tokens", async function () {
    //   const count = ethers.utils.parseEther("2");
    //   expect(await bondingCurveToken.getCurrentPrice()).to.be.equal(0);
    //   const currentPrice = await bondingCurveToken.getCurrentPrice();

    //   const PRICE_INCREASE_PER_TOKEN =
    //     await bondingCurveToken.PRICE_INCREASE_PER_TOKEN();
    //   const smallestUnitOfIncrease = PRICE_INCREASE_PER_TOKEN.div(
    //     ethers.utils.parseEther("0.0001")
    //   );
    //   const decimals = ethers.utils.parseEther("1");
    //   const endingPrice = currentPrice.add(
    //     PRICE_INCREASE_PER_TOKEN.mul(count).div(decimals)
    //   );
    //   const amountToPay = currentPrice
    //     .add(endingPrice)
    //     .add(smallestUnitOfIncrease)
    //     .mul(count)
    //     .div(decimals)
    //     .div(2);
    //   console.log(`currentPrice`, ethers.utils.formatEther(currentPrice));
    //   console.log(`endingPrice`, ethers.utils.formatEther(endingPrice));
    //   console.log(`amountToPay`, ethers.utils.formatEther(amountToPay));

    //   await bondingCurveToken.connect(userA).mintBondingCurve(count, {
    //     value: amountToPay,
    //   });

    //   expect(await bondingCurveToken.getCurrentPrice()).to.be.equal(
    //     endingPrice
    //   );
    //   expect(await bondingCurveToken.balanceOf(userA.address)).to.be.equal(
    //     count
    //   );

    //   expect(
    //     await bondingCurveToken.provider.getBalance(bondingCurveToken.address)
    //   ).to.be.equal(amountToPay);
    // });
  });
});
