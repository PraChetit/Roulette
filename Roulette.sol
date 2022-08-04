// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


/// @title Simple roulette betting.
///
/// This is a fun project to learn Solidity. Source of randomness is not at all safe!
/// The roulette virtually once in every block. The contract allows anyone to place a bet on whether
/// the number on roulette in a future block is odd or even. 
contract Roulette {

    /// @dev Represents the type of bet. Possible values are {Even, Odd}.
    enum BetType {
        Even,
        Odd
    }

    /// @dev Represents a bet.
    /// @param betType The type of bet placed.
    /// @param amount The amount in wei bet.
    /// @param blockNum The block number on which the bet is placed.
    /// @param pending Whether the bet is pending or already processed.
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

    /// Initializes the contract and sets the initial balances.
    constructor() payable {
        owner = payable(msg.sender);
        totalBalance = msg.value;
        freeBalance = msg.value;
    }

    /// Updates internal balanced upon payment into the contract.
    receive() external payable {
        totalBalance += msg.value;
        freeBalance += msg.value;
    }

    /// Withdraws specified amount to owner's address. Can only be called by the owner.
    /// @param amount The amount of wei to be withdrawn. Must be less than free balance.
    function withdraw(uint amount) external {
        require(msg.sender == owner, "Caller is not the owner.");
        require(amount <= freeBalance, "Not enough free balance to support the requested withdrawal.");
        freeBalance -= amount;
        totalBalance -= amount;
        payable(msg.sender).transfer(amount);
    }

    /// Bets `msg.value` on even number.
    /// Cannot be used if the `msg.sender` already has an unrealized bet.
    /// @param futureBlockNumber The block number on which the bet is placed. 
    ///   Must be greater than the current block number.
    function betOnEven(uint futureBlockNumber) external payable {
        _betOnParity(futureBlockNumber, BetType.Even);
    }

    /// Bets `msg.value` on odd number.
    /// Cannot be used if the `msg.sender` already has an unrealized bet.
    /// @param futureBlockNumber The block number on which the bet is placed. 
    ///   Must be greater than the current block number.
    function betOnOdd(uint futureBlockNumber) external payable {
        _betOnParity(futureBlockNumber, BetType.Odd);
    }

    /// Realizes a bet placed by the `msg.sender`.
    /// Must be executed in a block after the block on which the bet was placed.
    /// If the bet was won, sends back double the amount that was bet. Otherwise, nothing is sent.
    function realizeMyBet() external {
        Bet storage myBet = allBets[msg.sender];
        require(myBet.pending, "No pending bet for bettor.");
        require(myBet.blockNum < block.number, "Target block number does not exist yet.");

        uint8 spin = _unsafeRouletteSpin(myBet.blockNum);
        if (_decideParityWin(spin, myBet.betType)) {
            totalBalance -= 2 * myBet.amount;
            payable(msg.sender).transfer(2 * myBet.amount);
        } else {
            freeBalance += 2 * myBet.amount;
        }
        /// Make it possible to place another bet.
        myBet.pending = false;
    }

    /// @dev Helper to decide whether a bet was won or not.
    /// @param spin The number spun on the roulette.
    /// @param betType The type of the bet placed.
    /// @return Whether the bet is won.
    function _decideParityWin(uint8 spin, BetType betType) private pure returns (bool) {
        if (spin == 0) {
            return false;  // Zero is on the house.
        } else {
            return (betType == BetType.Even) ? (spin % 2) == 0 : (spin % 2) == 1;
        }
    }

    /// @dev Implements the bet on parity.
    /// The amount bet must be posotive and must be less than the free balance in the bank.
    /// Increments the total balance and decrements the free balance, tying it to the placed bet.
    function _betOnParity(uint futureBlockNumber, BetType betType) private {
        require(msg.value > 0, "Must bet a positive amount");
        require(msg.value < freeBalance, "Bank has insufficient funds to support this bet.");
        require(futureBlockNumber > block.number, "Bet must be placed in the future.");
        require(!allBets[msg.sender].pending, "Bettor already has a pending bet.");
        freeBalance -= msg.value;
        totalBalance += msg.value;
        allBets[msg.sender] = Bet(betType, msg.value, futureBlockNumber, true);
    }

    /// @dev Unsafely spins the roulette.
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
