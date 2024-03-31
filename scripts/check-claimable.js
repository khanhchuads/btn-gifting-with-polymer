const hre = require('hardhat');
const { getIbcApp } = require('./private/_vibc-helpers.js');

async function main() {
    const accounts = await hre.ethers.getSigners();

    const networkName = hre.network.name;
    // Get the contract type from the config and get the contract
    const ibcApp = await getIbcApp(networkName);
    
    // Send the packet
    const claimable = await ibcApp.connect(accounts[1]).checkClaimable();
    console.log(`
-------------------------------------------
🔗 🔒   CHECK CLAIMABLE !!!   🔗 🔒
-------------------------------------------`)
    console.log(`You are ${claimable ? 'eligible' : 'NOT eligible'} to claim gift at ${networkName === "optimism" ? "base" : "optimism"}\n`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});