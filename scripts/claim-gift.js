const hre = require('hardhat');
const { getConfigPath } = require('./private/_helpers');
const { getIbcApp } = require('./private/_vibc-helpers.js');

async function main() {
    const accounts = await hre.ethers.getSigners();
    const config = require(getConfigPath());
    const sendConfig = config.sendUniversalPacket;

    const networkName = hre.network.name;
    const ibcAppAddr = config["giftRefferal"][`${networkName}`];
    // Get the contract type from the config and get the contract
    console.log(`🗄️  Fetching IBC app on ${networkName} at address: ${ibcAppAddr}`)
    const contractType = 'GiftRefferal';
    const ibcApp = await ethers.getContractAt(
        `${contractType}`,
        ibcAppAddr
    );

    // Do logic to prepare the packet

    // If the network we are sending on is optimism, we need to use the base port address and vice versa
    const destPortAddr = networkName === "optimism" ?
                                            config["polyToken"]["base"] :
                                            config["polyToken"]["optimism"];
    const channelId = sendConfig[`${networkName}`]["channelId"];
    const channelIdBytes = hre.ethers.encodeBytes32String(channelId);
    const timeoutSeconds = sendConfig[`${networkName}`]["timeout"];
    
    // Send the packet
    await ibcApp.connect(accounts[1]).claimGift(
        destPortAddr,
        channelIdBytes,
        timeoutSeconds
    );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});