// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


contract Roulette {
    
    address payable public owner;

    constructor() payable {
        owner = payable(msg.sender);
    }

    receive() external payable {}

    function withdraw(uint _amount) external {
        require(msg.sender == owner, "Caller is not the owner.");
        payable(msg.sender).transfer(_amount);
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
