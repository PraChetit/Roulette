// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


contract Roulette {

    enum BetType {
        Even,
        Odd
    }

    struct Bet {
        BetType betType;
        uint amount;
        uint blockNum;
        bool pending;
    }

    address payable public owner;
    mapping(address => Bet) public allBets;
    uint public totalBalance;
    uint public freeBalance;

    constructor() payable {
        owner = payable(msg.sender);
        totalBalance = msg.value;
        freeBalance = msg.value;
    }

    receive() external payable {
        totalBalance += msg.value;
        freeBalance += msg.value;
    }

    function betOnEven(uint futureBlockNumber) external payable {
        _betOnParity(futureBlockNumber, BetType.Even);
    }

    function betOnOdd(uint futureBlockNumber) external payable {
        _betOnParity(futureBlockNumber, BetType.Odd);
    }

    function _betOnParity(uint futureBlockNumber, BetType betType) private {
        require(msg.value > 0, "Must bet a positive amount");
        require(msg.value < freeBalance, "Bank has insufficient funds to support this bet.");
        require(futureBlockNumber > block.number, "Bet must be placed in the future.");
        require(!allBets[msg.sender].pending, "Bettor already has a pending bet.");
        freeBalance -= msg.value;
        totalBalance += msg.value;
        allBets[msg.sender] = Bet(betType, msg.value, futureBlockNumber, true);
    }

    function realizeMyBet() external {
        Bet storage myBet = allBets[msg.sender];
        require(myBet.pending, "No pending bet for bettor.");
        require(myBet.blockNum < block.number, "Target block number does not exist yet.");

        uint8 spin = _unsafeRouletteSpin(myBet.blockNum) % 37;
        bool win;
        if (spin == 0) {
            // Zero is on the house.
            win = false;
        } else {
            win = (myBet.betType == BetType.Even) ? (spin % 2) == 0 : (spin % 2) == 1;
        }

        if (win) {
            totalBalance -= 2 * myBet.amount;
            payable(msg.sender).transfer(2 * myBet.amount);
        } else {
            freeBalance += 2 * myBet.amount;
        }

        myBet.pending = false;
    }

    function withdraw(uint amount) external {
        require(msg.sender == owner, "Caller is not the owner.");
        require(amount <= freeBalance, "Not enough free balance to support the requested withdrawal.");
        freeBalance -= amount;
        totalBalance -= amount;
        payable(msg.sender).transfer(amount);
    }

    function _unsafeRouletteSpin(uint blockNum) private view returns (uint8) {
        // bytes32 unsafeHashInput = blockhash(blockNum);
        // `blockhash` does not work with Remix VM, should work with a proper testnet, although with limitations:
        // https://docs.soliditylang.org/en/latest/units-and-global-variables.html#block-and-transaction-properties
        // For now, use timestample and add `blockNum * 232931707` (a randomly chosed prime number).
        bytes32 unsafeHashInput = bytes32(block.timestamp + block.number + blockNum * 232931707);
        bytes32 hash = keccak256(abi.encodePacked(unsafeHashInput));
        return uint8(uint(hash)) % 37;
    }

}
