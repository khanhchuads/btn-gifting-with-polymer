const hre = require('hardhat');
const { getConfigPath } = require('./private/_helpers');
const { getIbcApp } = require('./private/_vibc-helpers.js');

const _receiver = process.env.receiver;
const _deposit = process.env.deposit;
if (!_receiver || !_deposit) {
    console.error('Usage: receiver=<address> deposit=<amount> npx hardhat run create-gift.js --network <source>');
    process.exit(1);
}

async function main() {
    const accounts = await hre.ethers.getSigners();
    const config = require(getConfigPath());
    const sendConfig = config.sendUniversalPacket;

    const networkName = hre.network.name;
    // Get the contract type from the config and get the contract
    const ibcApp = await getIbcApp(networkName);

    // Do logic to prepare the packet

    // If the network we are sending on is optimism, we need to use the base port address and vice versa
    const destPortAddr = networkName === "optimism" ?
      config["sendUniversalPacket"]["base"]["portAddr"] :
      config["sendUniversalPacket"]["optimism"]["portAddr"];
    const channelId = sendConfig[`${networkName}`]["channelId"];
    const channelIdBytes = hre.ethers.encodeBytes32String(channelId);
    const timeoutSeconds = sendConfig[`${networkName}`]["timeout"];
    
    // Send the packet
    await ibcApp.connect(accounts[0]).createGift(
        destPortAddr,
        channelIdBytes,
        timeoutSeconds,
        _receiver,
        {
            value: hre.ethers.parseEther(_deposit),
        }
    );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});