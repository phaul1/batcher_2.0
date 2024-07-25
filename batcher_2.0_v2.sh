#!/bin/bash

function echo_blue_bold {
    echo -e "\033[1;34m$1\033[0m"
}
echo
echo_blue_bold "Enter RPC URL of the network:"
read providerURL
echo
echo_blue_bold "Enter private key:"
read privateKeys
echo
echo_blue_bold "Enter number of transaction types:"
read numberOfTransactionTypes
echo

declare -a contractAddresses
declare -a transactionDataArray
declare -a gasLimits
declare -a gasPrices

for ((i=1; i<=numberOfTransactionTypes; i++)); do
    echo_blue_bold "Enter contract address for transaction type $i:"
    read contractAddress
    contractAddresses+=("$contractAddress")
    
    echo_blue_bold "Enter transaction data (in hex) for transaction type $i:"
    read transactionData
    transactionDataArray+=("$transactionData")
    
    echo_blue_bold "Enter gas limit for transaction type $i:"
    read gasLimit
    gasLimits+=("$gasLimit")
    
    echo_blue_bold "Enter gas price (in gwei) for transaction type $i:"
    read gasPrice
    gasPrices+=("$gasPrice")
    echo
done

echo_blue_bold "Enter number of transactions to send per type:"
read numberOfTransactionsPerType
echo

if ! npm list ethers@5.5.4 >/dev/null 2>&1; then
  echo_blue_bold "Installing ethers..."
  npm install ethers@5.5.4
  echo
else
  echo_blue_bold "Ethers is already installed."
fi
echo

temp_node_file=$(mktemp /tmp/node_script.XXXXXX.js)

cat << EOF > $temp_node_file
const ethers = require("ethers");

const providerURL = "${providerURL}";
const provider = new ethers.providers.JsonRpcProvider(providerURL);

const privateKeys = "${privateKeys}";

const contractAddresses = ${JSON.stringify(contractAddresses)};
const transactionDataArray = ${JSON.stringify(transactionDataArray)};
const gasLimits = ${JSON.stringify(gasLimits)};
const gasPrices = ${JSON.stringify(gasPrices)};
const numberOfTransactionsPerType = ${numberOfTransactionsPerType};

function getRandomInt(max) {
    return Math.floor(Math.random() * max);
}

async function sendTransaction(wallet, txType) {
    const tx = {
        to: contractAddresses[txType],
        value: 0,
        gasLimit: ethers.BigNumber.from(gasLimits[txType]),
        gasPrice: ethers.utils.parseUnits(gasPrices[txType], 'gwei'),
        data: transactionDataArray[txType],
    };

    try {
        const transactionResponse = await wallet.sendTransaction(tx);
        console.log("\033[1;35mTx Hash:\033[0m", transactionResponse.hash);
        const receipt = await transactionResponse.wait();
        console.log("");
    } catch (error) {
        console.error("Error sending transaction:", error);
    }
}

async function main() {
    const wallet = new ethers.Wallet(privateKeys, provider);

    for (let txType = 0; txType < contractAddresses.length; txType++) {
        for (let i = 0; i < numberOfTransactionsPerType; i++) {
            console.log("Sending transaction", i + 1, "of type", txType + 1, "of", contractAddresses.length);
            await sendTransaction(wallet, txType);
            const randomDelay = getRandomInt(30000);
            console.log("Waiting for", randomDelay, "ms before sending the next transaction...");
            await new Promise(resolve => setTimeout(resolve, randomDelay));
        }
    }
}

main().catch(console.error);
EOF

NODE_PATH=$(npm root -g):$(pwd)/node_modules node $temp_node_file

rm $temp_node_file
echo
echo_blue_bold "Follow @iam_reggiehub on X for more guide like this"
echo
