#!/bin/bash

function echo_blue_bold {
    echo -e "\033[1;34m$1\033[0m"
}

# Function to install Node.js if not installed
function install_node {
    if ! command -v node &> /dev/null
    then
        echo_blue_bold "Node.js not found. Installing Node.js..."
        curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
        sudo apt install -y nodejs
    fi
}

# Function to install npm if not installed
function install_npm {
    if ! command -v npm &> /dev/null
    then
        echo_blue_bold "npm not found. Installing npm..."
        sudo apt install -y npm
    fi
}

# Ensure Node.js and npm are installed
install_node
install_npm

echo
echo_blue_bold "Enter RPC URL of the network:"
read providerURL
echo
echo_blue_bold "Enter private key:"
read privateKeys
echo
echo_blue_bold "Enter contract address:"
read contractAddress
echo

transactions=()

while true; do
    echo_blue_bold "Enter transaction data (in hex) (or 'done' to finish):"
    read transactionData
    if [ "$transactionData" == "done" ]; then
        break
    fi

    echo_blue_bold "Enter gas limit:"
    read gasLimit
    echo
    echo_blue_bold "Enter gas price (in gwei):"
    read gasPrice
    echo
    echo_blue_bold "Enter number of transactions to send:"
    read numberOfTransactions
    echo

    transaction="{\"transactionData\":\"$transactionData\",\"gasLimit\":\"$gasLimit\",\"gasPrice\":\"$gasPrice\",\"numberOfTransactions\":\"$numberOfTransactions\"}"
    transactions+=("$transaction")

    echo
done

if ! npm list -g ethers@5.5.4 >/dev/null 2>&1; then
  echo_blue_bold "Installing ethers..."
  npm install -g ethers@5.5.4
  echo
else
  echo_blue_bold "Ethers is already installed."
fi
echo

temp_node_file=$(mktemp /tmp/node_script.XXXXXX.js)

# Join transactions array into a JSON array string
transactions_json=$(printf ",%s" "${transactions[@]}")
transactions_json="[${transactions_json:1}]"

cat << EOF > $temp_node_file
const ethers = require("ethers");

const providerURL = "${providerURL}";
const provider = new ethers.providers.JsonRpcProvider(providerURL);

const privateKeys = "${privateKeys}";

const contractAddress = "${contractAddress}";

const transactions = ${transactions_json};

async function sendTransaction(wallet, txDetails) {
    const tx = {
        to: contractAddress,
        value: 0,
        gasLimit: ethers.BigNumber.from(txDetails.gasLimit),
        gasPrice: ethers.utils.parseUnits(txDetails.gasPrice, 'gwei'),
        data: txDetails.transactionData,
    };

    try {
        const transactionResponse = await wallet.sendTransaction(tx);
        console.log("\033[1;35mTx Hash:\033[0m", transactionResponse.hash);
        const receipt = await transactionResponse.wait();
        console.log("Transaction receipt:", receipt);
        console.log("");
    } catch (error) {
        console.error("Error sending transaction:", error);
        console.log("Transaction details:", tx);
    }
}

async function main() {
    const wallet = new ethers.Wallet(privateKeys, provider);

    // Check balance
    const balance = await wallet.getBalance();
    console.log("\033[1;34mAccount balance:\033[0m", ethers.utils.formatEther(balance), "ETH");

    for (const txDetails of transactions) {
        for (let i = 0; i < txDetails.numberOfTransactions; i++) {
            console.log("Sending transaction", i + 1, "of", txDetails.numberOfTransactions);
            await sendTransaction(wallet, txDetails);

            // Generate a random delay between 5 and 30 seconds
            const delay = Math.floor(Math.random() * (30 - 5 + 1) + 5) * 1000;
            console.log(\`Waiting for \${delay / 1000} seconds before sending the next transaction...\`);
            await new Promise(resolve => setTimeout(resolve, delay));
        }
    }
}

main().catch(console.error);
EOF

NODE_PATH=$(npm root -g):$(pwd)/node_modules node $temp_node_file

rm $temp_node_file
echo
echo_blue_bold "Stay Frosty DEGEN"
echo
