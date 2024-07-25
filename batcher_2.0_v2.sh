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

# Arrays to hold multiple transaction types' details
declare -a contractAddresses
declare -a transactionDataList
declare -a gasLimits
declare -a gasPrices
declare -a numberOfTransactionsList

while true; do
    echo_blue_bold "Enter contract address (or type 'done' to finish):"
    read contractAddress
    if [[ "$contractAddress" == "done" ]]; then
        break
    fi
    contractAddresses+=("$contractAddress")
    
    echo_blue_bold "Enter transaction data (in hex):"
    read transactionData
    transactionDataList+=("$transactionData")
    
    echo_blue_bold "Enter gas limit:"
    read gasLimit
    gasLimits+=("$gasLimit")
    
    echo_blue_bold "Enter gas price (in gwei):"
    read gasPrice
    gasPrices+=("$gasPrice")
    
    echo_blue_bold "Enter number of transactions to send for this type:"
    read numberOfTransactions
    numberOfTransactionsList+=("$numberOfTransactions")
    
    echo
done

if ! npm list ethers@5.5.4 >/dev/null 2>&1; then
    echo_blue_bold "Installing ethers..."
    npm install ethers@5.5.4
    echo
else
    echo_blue_bold "Ethers is already installed."
fi
echo

temp_node_file=$(mktemp /tmp/node_script.XXXXXX.js)

# Create JSON string representations of the arrays
contractAddressesJson=$(printf '%s\n' "${contractAddresses[@]}" | jq -R . | jq -s .)
transactionDataListJson=$(printf '%s\n' "${transactionDataList[@]}" | jq -R . | jq -s .)
gasLimitsJson=$(printf '%s\n' "${gasLimits[@]}" | jq -R . | jq -s .)
gasPricesJson=$(printf '%s\n' "${gasPrices[@]}" | jq -R . | jq -s .)
numberOfTransactionsListJson=$(printf '%s\n' "${numberOfTransactionsList[@]}" | jq -R . | jq -s .)

cat << EOF > $temp_node_file
const ethers = require("ethers");

const providerURL = "$providerURL";
const provider = new ethers.providers.JsonRpcProvider(providerURL);

const privateKeys = "$privateKeys";

// Arrays holding multiple transaction types' details
const contractAddresses = $contractAddressesJson;
const transactionDataList = $transactionDataListJson;
const gasLimits = $gasLimitsJson;
const gasPrices = $gasPricesJson;
const numberOfTransactionsList = $numberOfTransactionsListJson;

async function sendTransaction(wallet, contractAddress, transactionData, gasLimit, gasPrice) {
    const tx = {
        to: contractAddress,
        value: 0,
        gasLimit: ethers.BigNumber.from(gasLimit),
        gasPrice: ethers.utils.parseUnits(gasPrice, 'gwei'),
        data: transactionData,
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

    for (let i = 0; i < contractAddresses.length; i++) {
        const contractAddress = contractAddresses[i];
        const transactionData = transactionDataList[i];
        const gasLimit = gasLimits[i];
        const gasPrice = gasPrices[i];
        const numberOfTransactions = numberOfTransactionsList[i];

        for (let j = 0; j < numberOfTransactions; j++) {
            console.log(\`Sending transaction type \${i + 1} transaction \${j + 1} of \${numberOfTransactions}\`);
            await sendTransaction(wallet, contractAddress, transactionData, gasLimit, gasPrice);
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
