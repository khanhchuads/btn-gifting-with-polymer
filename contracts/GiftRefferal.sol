//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./base/UniversalChanIbcApp.sol";

contract GiftRefferal is UniversalChanIbcApp {

    enum GIFT_STATUS {
        CREATE,
        MINTED,
        CLAIM,
        CLAIMED
    }

    mapping (address => uint) private gifts; // for OP chain to store gift amount value for each receiver
    mapping (address => uint) private lockedAmount; // for BASE chain to store locked amount value for each receiver who will be received amount as the fee on new chain
    
    constructor(address _middleware) UniversalChanIbcApp(_middleware) {}

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
        address _receiver
    ) external payable {
        require(msg.value > 0, "Your gift amount must be greater than 0");
        require(_receiver != msg.sender, "You can't send a gift to yourself");
        
        bytes memory payload = abi.encode(msg.sender, msg.value, _receiver, GIFT_STATUS.CREATE);

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
        bytes memory payload = abi.encode(msg.sender, gifts[msg.sender], msg.sender, GIFT_STATUS.CLAIM);

        uint64 timeoutTimestamp = uint64((block.timestamp + timeoutSeconds) * 1000000000);

        IbcUniversalPacketSender(mw).sendUniversalPacket(
            channelId, IbcUtils.toBytes32(destPortAddr), payload, timeoutTimestamp
        );
    }

    /**
     * @dev Packet lifecycle callback that implements packet receipt logic and returns and acknowledgement packet.
     *      MUST be overriden by the inheriting contract.
     *
     * @param channelId the ID of the channel (locally) the packet was received on.
     * @param packet the Universal packet encoded by the source and relayed by the relayer.
     */
    function onRecvUniversalPacket(bytes32 channelId, UniversalPacket calldata packet)
        external
        override
        onlyIbcMw
        returns (AckPacket memory ackPacket)
    {
        recvedPackets.push(UcPacketWithChannel(channelId, packet));

        (address sender, uint amount, address _receiver, GIFT_STATUS giftStatus) = abi.decode(
                                                                                        packet.appData, 
                                                                                        (address, uint, address, GIFT_STATUS)
                                                                                    );
        if (giftStatus == GIFT_STATUS.CREATE) {
            // Do save receiver address for gift
            gifts[_receiver] = amount;
            giftStatus = GIFT_STATUS.MINTED;
        } else if (giftStatus == GIFT_STATUS.CLAIM) {
            // do transfer amount to receiver
            require(sender == _receiver, "You are not the receiver of this gift");
            payable(_receiver).transfer(lockedAmount[_receiver]);
            lockedAmount[_receiver] = 0; // clear locked amount
            giftStatus = GIFT_STATUS.CLAIMED;
        }

        return AckPacket(true, abi.encode(sender, amount, _receiver, giftStatus));
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
        ackPackets.push(UcAckWithChannel(channelId, packet, ack));
        (address sender, uint amount, address _receiver, GIFT_STATUS giftStatus) = abi.decode(
                                                                                        ack.data, 
                                                                                        (address, uint, address, GIFT_STATUS)
                                                                                    );
        if (giftStatus == GIFT_STATUS.CLAIMED) {
            // do clear receiver address for gift
            gifts[_receiver] = 0;
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