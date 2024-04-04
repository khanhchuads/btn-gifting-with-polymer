// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import './base/UniversalChanIbcApp.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract PolymerERC20 is UniversalChanIbcApp, ERC20 {

    mapping (address => uint256) private claimablePool;

    constructor(string memory name, string memory symbol, address _middleware) ERC20(name, symbol) UniversalChanIbcApp(_middleware) {
        _mint(address(this), 100000000 * 10 ** decimals()); 
    }

    function mintMyself(address account, uint256 amount) external onlyOwner  {
        _mint(account, amount);
    }

    function mint(address account, uint256 amount) internal  {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) internal {
        _burn(account, amount);
    }

    function onRecvUniversalPacket(
        bytes32 channelId,
        UniversalPacket calldata packet
    ) external override onlyIbcMw returns (AckPacket memory ackPacket) {
        (address sender,
        uint256 amount,
        string memory eventType,
        address receiver) = abi.decode(packet.appData, (address, uint256, string, address));

        if (keccak256(abi.encodePacked(eventType)) == keccak256(abi.encodePacked('createGift'))) {
            claimablePool[receiver] += amount;
        } else if (keccak256(abi.encodePacked(eventType)) == keccak256(abi.encodePacked('claimGift'))) {
            require(sender == receiver, "Only receiver can claim the gift");
            _mint(receiver, claimablePool[receiver] * 10**18);
            claimablePool[receiver] = 0; // reset claimable amount
            return AckPacket(true, abi.encode(0));
        } else {
            return AckPacket(false, abi.encode(0));
        }
    }

    function onTimeoutUniversalPacket(bytes32 channelId, UniversalPacket calldata packet) external override onlyIbcMw {
        (address sender, uint256 amount, string memory eventType, address receiver) = abi.decode(packet.appData, (address, uint256, string, address));
        if (keccak256(abi.encodePacked(eventType)) == keccak256(abi.encodePacked('createGift'))) {
            
        } else if (keccak256(abi.encodePacked(eventType)) == keccak256(abi.encodePacked('claimGift'))) {
            
        }
    }
}
