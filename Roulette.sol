// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


contract Roulette {

    enum BetType {
        Black,
        Red
    }

    struct Bet {
        address bettor;
        BetType betType;
        uint amount;
        uint blockNum;
    }

    address payable public owner;
    mapping(address => Bet[]) public unrealizedBets;
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

    function betOnBlack(uint futureBlockNumber) external payable {
        _betOnColor(futureBlockNumber, BetType.Black);
    }

    function betOnRed(uint futureBlockNumber) external payable {
        _betOnColor(futureBlockNumber, BetType.Red);
    }

    function _betOnColor(uint futureBlockNumber, BetType betType) private {
        require(msg.value > 0, "Must bet a positive amount");
        require(msg.value < freeBalance, "Bank has insufficient funds to support this bet.");
        require(futureBlockNumber > block.number, "Bet must be placed in the future.");
        freeBalance -= msg.value;
        totalBalance += msg.value;
        Bet memory newBet = Bet(msg.sender, betType, msg.value, futureBlockNumber);
        unrealizedBets[msg.sender].push(newBet);
    }

    function withdraw(uint amount) external {
        require(msg.sender == owner, "Caller is not the owner.");
        require(amount <= freeBalance, "Not enough free balance to support the requested withdrawal.");
        payable(msg.sender).transfer(amount);
    }

    function _unsafeRouletteSpin(uint blockNum) private view returns (uint8) {
        // bytes32 unsafeHashInput = blockhash(blockNum) ^ bytes32(block.timestamp + block.number);
        // `blockhash` does not work with Remix VM, should work with a proper testnet, although with limitations:
        // https://docs.soliditylang.org/en/latest/units-and-global-variables.html#block-and-transaction-properties
        // For now, add `blockNum * 232931707` (a randomly chosed prime number).
        bytes32 unsafeHashInput = bytes32(block.timestamp + block.number + blockNum * 232931707);
        bytes32 hash = keccak256(abi.encodePacked(unsafeHashInput));
        return uint8(uint(hash)) % 37;
    }

}
