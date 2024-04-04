//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./base/UniversalChanIbcApp.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GiftRefferal is UniversalChanIbcApp {

    IERC20 private polyToken;

    mapping (address => uint) private gifts; // for OP chain to store gift amount value for each receiver
    
    constructor(address _middleware, address polyTokenAddr) UniversalChanIbcApp(_middleware) {
        polyToken = IERC20(polyTokenAddr);
    }

    /**
     * @dev Sends a packet with the caller's address over the universal channel.
     * @param destPortAddr The address of the destination application.
     * @param channelId The ID of the channel to send the packet to.
     * @param timeoutSeconds The timeout in seconds (relative).
     * @param _receiver The address of the receiver.
     */
    function createGift(
        address destPortAddr,
        bytes32 channelId,
        uint64 timeoutSeconds,
        address _receiver,
        uint256 amount
    ) external payable {
        require(_receiver != msg.sender, "You can't send a gift to yourself");
        require(polyToken.transferFrom(msg.sender, address(this), amount * 10 ** 18), "You have not enough balance to send gift");
        
        bytes memory payload = abi.encode(msg.sender, amount, 'createGift', _receiver);

        uint64 timeoutTimestamp = uint64((block.timestamp + timeoutSeconds) * 1000000000);

        IbcUniversalPacketSender(mw).sendUniversalPacket(
            channelId, IbcUtils.toBytes32(destPortAddr), payload, timeoutTimestamp
        );
    }

    /**
     * @dev check claimable.
     */
    function checkClaimable() external view returns (bool) {
        return gifts[msg.sender] > 0;
    }

    /**
     * @dev Claim gift.
     * @param destPortAddr The address of the destination application.
     * @param channelId The ID of the channel to send the packet to.
     * @param timeoutSeconds The timeout in seconds (relative).
     */
    function claimGift(
        address destPortAddr,
        bytes32 channelId,
        uint64 timeoutSeconds
    ) external {
        require(gifts[msg.sender] > 0, "You don't have any gift to claim");
        bytes memory payload = abi.encode(msg.sender, gifts[msg.sender], 'claimGift', msg.sender);

        uint64 timeoutTimestamp = uint64((block.timestamp + timeoutSeconds) * 1000000000);

        IbcUniversalPacketSender(mw).sendUniversalPacket(
            channelId, IbcUtils.toBytes32(destPortAddr), payload, timeoutTimestamp
        );
    }

    /**
     * @dev Packet lifecycle callback that implements packet acknowledgment logic.
     *      MUST be overriden by the inheriting contract.
     *
     * @param channelId the ID of the channel (locally) the ack was received on.
     * @param packet the Universal packet encoded by the source and relayed by the relayer.
     * @param ack the acknowledgment packet encoded by the destination and relayed by the relayer.
     */
    function onUniversalAcknowledgement(bytes32 channelId, UniversalPacket memory packet, AckPacket calldata ack)
        external
        override
        onlyIbcMw
    {
        (address sender, uint256 amount, string memory eventType, address receiver) = abi.decode(packet.appData, (address, uint256, string, address));
        if (ack.success) {
            if (keccak256(abi.encodePacked(eventType)) == keccak256(abi.encodePacked('createGift'))) {
                // create gift successfully
                gifts[receiver] += amount;
            } else if (keccak256(abi.encodePacked(eventType)) == keccak256(abi.encodePacked('claimGift'))) {
                // claim gift successfully
                gifts[receiver] = 0; // reset
            }
        } else {
            if (keccak256(abi.encodePacked(eventType)) == keccak256(abi.encodePacked('createGift'))) {
                // create gift ack failed, return assets for user
                polyToken.transferFrom(address(this), sender, amount * 10 ** 18);
            }
        }
    }

    /**
     * @dev Packet lifecycle callback that implements packet receipt logic and return and acknowledgement packet.
     *      MUST be overriden by the inheriting contract.
     *      NOT SUPPORTED YET
     *
     * @param channelId the ID of the channel (locally) the timeout was submitted on.
     * @param packet the Universal packet encoded by the counterparty and relayed by the relayer
     */
    function onTimeoutUniversalPacket(bytes32 channelId, UniversalPacket calldata packet) external override onlyIbcMw {
        timeoutPackets.push(UcPacketWithChannel(channelId, packet));
        // do logic
    }
}