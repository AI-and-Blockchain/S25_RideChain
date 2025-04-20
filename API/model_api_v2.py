from web3 import Web3
from flask import Flask
import json
import threading
import time
from web3._utils.events import get_event_data

# Custom model prediction imports
import pickle
import os
import nltk
from nltk.sentiment.vader import SentimentIntensityAnalyzer
import re
import pandas as pd

nltk.download('vader_lexicon')

app = Flask(__name__)

# Blockchain setup
w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:8545"))
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

# Load model
def load_model(model_path):
    with open(model_path, 'rb') as file:
        model_dict = pickle.load(file)
    return model_dict['vectorizer'], model_dict['model'], model_dict['neutral_lower'], model_dict['neutral_upper']

model_path = 'API/driver_rating_model.pkl'
vectorizer, model, neutral_lower, neutral_upper = load_model(model_path)

# Preprocess text
def preprocess_text(text):
    if not isinstance(text, str) or pd.isna(text):
        return ""
    text = text.lower()
    text = re.sub(r'[^a-z0-9\s]', ' ', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text

# Prediction function
def predict_rating(review_text, vectorizer, model, neutral_lower=-0.1, neutral_upper=0.1):
    sid = SentimentIntensityAnalyzer()
    processed = preprocess_text(review_text)
    sentiment = sid.polarity_scores(review_text)['compound']
    features = vectorizer.transform([processed])
    model_prediction = model.predict(features)[0]
    probabilities = model.predict_proba(features)[0]
    prob_dict = {i+1: prob for i, prob in enumerate(probabilities)}

    final_prediction = model_prediction
    if neutral_lower <= sentiment <= neutral_upper:
        final_prediction = 3
    elif sentiment > 0.7 and model_prediction < 4:
        final_prediction = max(model_prediction, 4)
    elif sentiment < -0.7 and model_prediction > 2:
        final_prediction = min(model_prediction, 2)

    return {
        'rating': final_prediction,
        'sentiment': sentiment,
        'probabilities': prob_dict
    }

# Main event handler
def handle_score_update_request(decoded_event):
    driver = decoded_event['args']['driver']
    feedback = decoded_event['args']['feedback']
    print(f"Received score update request for {driver} with feedback: '{feedback}'")

    try:
        result = predict_rating(feedback, vectorizer, model, neutral_lower, neutral_upper)
        new_score = result['rating']
        print(f"Sentiment: {result['sentiment']:.2f} -> Rating: {new_score}")
        print(f"Probabilities: {result['probabilities']}")
    except Exception as e:
        print(f"Error in model prediction: {e}")
        new_score = 3  # default neutral

    tx = oracle_contract.functions.updateDriverScore(driver, int(abs(new_score))).build_transaction({
        'from': oracle_account.address,
        'nonce': w3.eth.get_transaction_count(oracle_account.address),
        'gas': 100000,
        'gasPrice': w3.to_wei('1', 'gwei'),
        'chainId': w3.eth.chain_id
    })

    signed_tx = oracle_account.sign_transaction(tx)
    tx_hash = w3.eth.send_raw_transaction(signed_tx.raw_transaction)
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
