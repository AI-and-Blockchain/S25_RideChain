from web3 import Web3
from flask import Flask
import json
import threading
import time
from web3._utils.events import get_event_data
from transformers import pipeline

app = Flask(__name__)

# Connect to local blockchain
w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:8545"))

# Replace with your deployed contract address
contract_address = Web3.to_checksum_address("0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512")

# Load ABI
with open("API/AIRatingOracleContract.json", "r") as f:
    abi = json.load(f)["abi"]

# Contract instance
oracle_contract = w3.eth.contract(address=contract_address, abi=abi)

# Oracle account setup
oracle_private_key = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
oracle_account = w3.eth.account.from_key(oracle_private_key)

# Event ABI
event_abi = oracle_contract.events.DriverScoreUpdateRequested._get_event_abi()
event_signature_hash = w3.keccak(text="DriverScoreUpdateRequested(address,string)").hex()

sentiment_analyzer = pipeline("sentiment-analysis")

def sentiment_to_score(sentiment_label, score_prob):
    """
    Convert sentiment label and score into 1–5 rating.
    """
    if sentiment_label == "NEGATIVE":
        if score_prob > 0.9:
            return 1
        elif score_prob > 0.7:
            return 2
        else:
            return 3
    else:
        if score_prob > 0.9:
            return 5
        elif score_prob > 0.7:
            return 4
        else:
            return 3
        

def handle_score_update_request(decoded_event):
    driver = decoded_event['args']['driver']
    feedback = decoded_event['args']['feedback']
    print(f"Received score update request for {driver} with feedback: '{feedback}'")

    # Mock AI scoring logic
    # new_score = 5 if "good" in feedback.lower() else 1
    try:
        result = sentiment_analyzer(feedback)[0]
        sentiment_label = result['label']
        sentiment_score = result['score']
        new_score = sentiment_to_score(sentiment_label, sentiment_score)
        print(f"Sentiment: {sentiment_label} ({sentiment_score:.2f}) -> Rating: {new_score}")
    except Exception as e:
        print(f"Error in sentiment analysis: {e}")
        new_score = 3  # default to neutral

    tx = oracle_contract.functions.updateDriverScore(driver, new_score).build_transaction({
        'from': oracle_account.address,
        'nonce': w3.eth.get_transaction_count(oracle_account.address),
        'gas': 100000,
        'gasPrice': w3.to_wei('1', 'gwei'),
        'chainId': w3.eth.chain_id
    })

    signed_tx = oracle_account.sign_transaction(tx)  # Changed signing method
    tx_hash = w3.eth.send_raw_transaction(signed_tx.raw_transaction)  # Send the signed transaction
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    print(f"Updated driver score with new score of {new_score}, tx hash: {tx_hash.hex()}")

    response_event_abi = oracle_contract.events.OracleResponseReceived._get_event_abi()
    response_event_signature_hash = w3.keccak(text="OracleResponseReceived(address,uint256)").hex()

    response_filter = w3.eth.filter({
        "address": oracle_contract.address,
        "topics": [response_event_signature_hash],
        "fromBlock": receipt.blockNumber,
        "toBlock": receipt.blockNumber
    })

    # Wait briefly for event to be mined and logged
    time.sleep(3)
    response_events = response_filter.get_new_entries()

    for ev in response_events:
        try:
            decoded_response = get_event_data(w3.codec, response_event_abi, ev)
            print(f"Oracle confirmed update for driver {decoded_response['args']['driver']} with new score: {decoded_response['args']['newScore']}")
        except Exception as e:
            print(f"Error decoding OracleResponseReceived: {e}")

def event_listener():
    print("Listening for DriverScoreUpdateRequested events...")
    event_filter = w3.eth.filter({
        "address": oracle_contract.address,
        "topics": [event_signature_hash],
        "fromBlock": "latest"
    })

    while True:
        for event in event_filter.get_new_entries():
            try:
                decoded_event = get_event_data(w3.codec, event_abi, event)
                handle_score_update_request(decoded_event)
            except Exception as e:
                print(f"Error decoding event: {e}")
        time.sleep(2)

@app.route("/")
def healthcheck():
    return "Oracle is running!"

if __name__ == "__main__":
    listener_thread = threading.Thread(target=event_listener, daemon=True)
    listener_thread.start()
    app.run(port=5001)
