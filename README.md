#  Quest-Into-The-Polyverse-Phase-1 : A gift link to help friends onboard to a new chain

# Team Members
- @btuyen2606 - Lead Developer 
- @khanhchuads - Developer

# Description
I have a friend who has never experienced any dapps on Base. I want to create a gift referral to give him a small amount of fees on the Base chain.
I will create a gift, enter my friend's wallet address, and deposit a certain amount of fees for him on the Base chain. When creating the gift, the contract will use the Universal Channel to send a packet and create a referral for my friend on OP, so he only needs to claim it on OP to receive the fees I deposited for him to experience on Base.

Features:
- Uses Polymer x IBC as the cross-chain format
- The user creates a gift, enters the wallet address, and sends a certain fee on the Base chain. When creating a gift, the contract will use Universal Channel to send packets and create referal links on OP. The recipient only needs to claim on OP to receive a fee to experience on Base.

# Resources used
The repo uses the ibc-app-solidity-template as starting point and adds custom contracts Raffle and RaffleNFT that implement the custom logic.

It changes the send-packet.js script slightly to adjust to the custom logic.

Additional resources used:
- Hardhat
- Blockscout

# Steps
## Prerequisites
- Ensure you have a Web3 wallet like MetaMask installed for interaction with the blockchain.
- Have a sufficient balance of ETH on Optimism for transaction fees and participating in the game.

## Installation and Setup
Clone the repository to your local environment. 
```bash
git clone https://github.com/btuyen2606/btn-gifting-with-polymer
```

After cloning the repo, install dependencies:
```bash
just install
```
After cloning the repository and navigating into the project directory, follow these steps to initialize the project and start.

## Initialize Project

# Proof of Testnet Interaction

After following the steps above you should have interacted with the testnet. You can check this at the IBC Explorer.

Here's the data of our application:


Proof of Testnet interaction:


# Challenges Faced
Debugging was a bit tricky when the sendPacket part worked fine on the contract, but there was a problem later with the packet.


# License
 
[MIT](https://choosealicense.com/licenses/mit/)
