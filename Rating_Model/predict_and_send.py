import joblib
import yaml
import numpy as np
import json
from web3 import Web3

# ---------------------------------------------
# Load config
# ---------------------------------------------
with open("config.yaml", "r") as f:
    config = yaml.safe_load(f)

model_path = config["model_path"]

# Load trained driver rating model
model = joblib.load(model_path)

# Simulated driver metrics (replace this later with real input)
driver_metrics = {
    "accept_delay_avg": 43.2,
    "avg_duration": 11.1,
    "prime_time_ratio": 0.22,
    "ride_count": 35
}

# Format input for prediction
X_input = np.array([[driver_metrics["accept_delay_avg"],
                     driver_metrics["avg_duration"],
                     driver_metrics["prime_time_ratio"],
                     driver_metrics["ride_count"]]])

# Predict driver rating (0 to 3)
predicted_rating = int(model.predict(X_input)[0])
print(f"Predicted Rating: {predicted_rating}")

# Connect to Anvil (Forge local blockchain)
w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:8545"))

# Use test account from Anvil output
# (replace with our anvil account)
# Run `anvil` in terminal to get accounts + private keys
sender_address = Web3.to_checksum_address("0xYOUR_ANVIL_ACCOUNT")       # e.g. "0xF39...abc"
private_key     = "0xYOUR_ANVIL_PRIVATE_KEY"                             # e.g. "0x59c...abc"

# Load ABI (from `forge inspect RideChain abi > RideChainABI.json`)
with open("blockchain/RideChainABI.json", "r") as abi_file:
    abi = json.load(abi_file)

# Contract address from Forge deployment
contract_address = Web3.to_checksum_address("0xYOUR_DEPLOYED_CONTRACT")

# Create contract instance
contract = w3.eth.contract(address=contract_address, abi=abi)

# For now, we'll assume sender == driver
driver_address = sender_address

# Build the transaction to call `updateDriverRating(address, uint8)`
tx = contract.functions.updateDriverRating(driver_address, predicted_rating).build_transaction({
    "from": sender_address,
    "nonce": w3.eth.get_transaction_count(sender_address),
    "gas": 200000,
    "gasPrice": w3.to_wei("10", "gwei")
})

# Sign and send the transaction
signed_tx = w3.eth.account.sign_transaction(tx, private_key=private_key)
tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)

print(f"Transaction sent: {tx_hash.hex()}")
