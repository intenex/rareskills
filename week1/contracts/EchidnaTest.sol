pragma solidity ^0.8.17;

import {ERC1363BondingCurve} from "./ERC1363BondingCurve.sol";

// We are using an external testing methodology
contract EchidnaTest is ERC1363BondingCurve {
    event Debug(string, uint256);

    // setup
    constructor() ERC1363BondingCurve("Echidna Test", "ECHID") {}

    // test minting the tokens and selling them to each other and make sure it all works

    function mintBondingCurveAndRefund() public payable {
        uint256 startingContractBalance = contractBalance();
        emit Debug("before everything", startingContractBalance);
        uint256 currentPrice = getCurrentPrice();
        uint256 amountToMint = ((msg.value / currentPrice) * oneToken()) / 10; // just to be safe set the amount to 10 times less than the maximum you could buy
        mintBondingCurve(amountToMint);
        emit Debug("after minting", contractBalance());
        assert(balanceOf(msg.sender) == amountToMint);
        assert(totalSupply() == amountToMint);
        assert(contractBalance() >= startingContractBalance);
        transferAndCall(address(this), amountToMint);
        emit Debug("after refund", contractBalance());
        assert(balanceOf(msg.sender) == 0);
        assert(totalSupply() == 0);
        assert(contractBalance() == startingContractBalance);
    }
}
