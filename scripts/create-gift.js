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
    const ibcAppAddr = config["giftRefferal"][`${networkName}`];

    // approval
    const erc20Address = config['polyToken'][networkName];
    const erc20Contract = 'PolymerERC20';
    console.log(`🗄️  Fetching ERC20 on ${networkName} at address: ${erc20Address}`);
    const token = await hre.ethers.getContractAt(`${erc20Contract}`, erc20Address);

    const approveTx = await token.approve(
        ibcAppAddr,
        hre.ethers.parseUnits(_deposit)
    );
    await approveTx.wait();

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
    await ibcApp.connect(accounts[0]).createGift(
        destPortAddr,
        channelIdBytes,
        timeoutSeconds,
        _receiver,
        _deposit
    );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});