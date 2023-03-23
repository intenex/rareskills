// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract GuessTheSecretNumberAttacker {
    bytes32 answerHash =
        0xdb81b4d58595fbbbb592d3661a34cdca14d7ab379441400cbfa1b78bc447c365;
    GuessTheSecretNumberChallenge guessContract;

    constructor(address _guessContract) {
        guessContract = GuessTheSecretNumberChallenge(_guessContract);
    }

    function guessNumber(uint8 _guess) external payable {
        require(msg.value == 1 ether);
        for (uint8 i = 0; i <= 255; i++) {
            if (keccak256(i) == answerHash) {
                guessContract.guess.value(msg.value)(_guess);
                return;
            }
        }
    }
}

interface GuessTheSecretNumberChallenge {
    function guess(uint8 n) external payable;
}
