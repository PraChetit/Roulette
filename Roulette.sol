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

}
