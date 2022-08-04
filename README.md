### Roulette

A toy project implementing a roulette as Ethereum smart contract in Solidity.

The roulette virtually spins in every block of the blockchain. 

Anyone can place bet on a spin in a `futureBlockNumber` using the `betOnEven` and `betOnOdd` functions. The size 
of the bets are limited by the amount of ETH in the contract not bound to other placed bets. The bet can be 
realized (paid out - or not) in a block after `futureBlockNumber` using the `realizeMyBet` function.