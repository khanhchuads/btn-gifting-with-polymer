const { exec } = require("child_process");
const {getConfigPath, getWhitelistedNetworks} = require('./private/_helpers.js');
const { setupIbcPacketEventListener } = require('./private/_events.js');

const source = process.argv[2];
if (!source) {
  console.error('Usage: node scripts/_config-claim.js <source>');
  process.exit(1);
}

function runSendPacketCommand(command) {
  return new Promise((resolve, reject) => {
    exec(command, (error, stdout, stderr) => {
      if (error) {
        console.error(`exec error: ${error}`);
        reject(error);
      } else {
        console.log(stdout);
        resolve(true);
      }
    });
  });
}

async function runSendPacket(config) {
  // Check if the source chain from user input is whitelisted
  const allowedNetworks = getWhitelistedNetworks();
  if (!allowedNetworks.includes(source)) {
    console.error("❌ Please provide a valid source chain");
    process.exit(1);
  }

  const script = 'claim-gift.js';
  const command = `npx hardhat run scripts/${script} --network ${source}`;

  try {
    await setupIbcPacketEventListener();
    await runSendPacketCommand(command);
  } catch (error) {
    console.error("❌ Error sending packet: ", error);
    process.exit(1);
  }
}

async function main() {
  const configPath = getConfigPath();
  const config = require(configPath);

  await runSendPacket(config);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});