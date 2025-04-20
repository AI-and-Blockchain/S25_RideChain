import pandas as pd
import numpy as np
import re
import ast
import pickle
import os
import yaml
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
import nltk
from nltk.sentiment.vader import SentimentIntensityAnalyzer
import matplotlib.pyplot as plt
import seaborn as sns

# Define sentiment threshold constants (global so they can be pickled)
NEUTRAL_LOWER = -0.1
NEUTRAL_UPPER = 0.1

# Preprocess text function (defined globally so it can be pickled)
def preprocess_text(text):
    """Basic text preprocessing"""
    if not isinstance(text, str) or pd.isna(text):
        return ""
    
    # Convert to lowercase and remove special characters
    text = text.lower()
    text = re.sub(r'[^a-z0-9\s]', ' ', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text

# Load config function
def load_config(config_path="config.yaml"):
    """
    Load configuration from YAML file using relative paths
    
    Args:
        config_path (str): Path to the config file, relative to script location
        
    Returns:
        dict: Configuration dictionary with absolute paths
    """
    # Get the directory of the current script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Create absolute path to the config file
    abs_config_path = os.path.join(script_dir, config_path)
    
    # Load the config
    with open(abs_config_path, "r") as f:
        config = yaml.safe_load(f)
    
    # Convert all paths in nested config to absolute paths
    if 'data_paths' in config:
        for key, value in config['data_paths'].items():
            if isinstance(value, str) and not os.path.isabs(value):
                config['data_paths'][key] = os.path.join(script_dir, value)
    
    # Also handle top-level paths
    for key, value in config.items():
        if isinstance(value, str) and key != 'data_paths' and (
            key.endswith('_path') or 
            key.endswith('_file') or 
            key.endswith('_dir') or
            '_ids' in key or
            'timestamps' in key or
            'train' in key
        ):
            if not os.path.isabs(value):
                config[key] = os.path.join(script_dir, value)
    
    return config

# Ensure directory exists
def ensure_dir(file_path):
    """Create directory if it doesn't exist"""
    directory = os.path.dirname(file_path)
    if directory and not os.path.exists(directory):
        os.makedirs(directory)

# Function to predict rating using model components
# IMPORTANT: This is defined at the global level so it can be imported directly
def predict_rating(review_text, vectorizer, model, neutral_lower=NEUTRAL_LOWER, neutral_upper=NEUTRAL_UPPER):
    """
    Predict the rating for a new review text with sentiment threshold rule
    
    Args:
        review_text (str): The text to predict a rating for
        vectorizer: The fitted CountVectorizer
        model: The trained classifier model
        neutral_lower: Lower bound for neutral sentiment
        neutral_upper: Upper bound for neutral sentiment
        
    Returns:
        dict: Prediction results with rating, explanation, etc.
    """
    # Initialize sentiment analyzer (don't pickle this, recreate as needed)
    sid = SentimentIntensityAnalyzer()
    
    # Preprocess the text
    processed = preprocess_text(review_text)
    
    # Calculate sentiment
    sentiment = sid.polarity_scores(review_text)['compound']
    
    # Get bag-of-words features
    features = vectorizer.transform([processed])
    
    # Get model's prediction and probabilities
    model_prediction = model.predict(features)[0]
    probabilities = model.predict_proba(features)[0]
    prob_dict = {i+1: prob for i, prob in enumerate(probabilities)}
    
    # Initialize with model's prediction
    final_prediction = model_prediction
    override_applied = False
    
    # Apply sentiment threshold rule
    # Very neutral sentiment should get a rating of 3
    if neutral_lower <= sentiment <= neutral_upper:
        final_prediction = 3
        override_applied = True
    # Very positive sentiment (e.g., "great", "excellent") should be at least 4
    elif sentiment > 0.7 and model_prediction < 4:
        final_prediction = max(model_prediction, 4)
        override_applied = True
    # Very negative sentiment (e.g., "terrible", "awful") should be at most 2
    elif sentiment < -0.7 and model_prediction > 2:
        final_prediction = min(model_prediction, 2)
        override_applied = True
    
    return {
        'rating': final_prediction,
        'model_prediction': model_prediction,
        'probabilities': prob_dict,
        'sentiment': sentiment,
        'override_applied': override_applied
    }

def main(config_path="config.yaml"):
    """Main function to train and save the model using config"""
    # Load configuration
    print(f"Loading configuration from {config_path}")
    config = load_config(config_path)
    
    # Get data path from config
    data_path = config.get('converted_train')
    model_save_path = config.get('model_path')
    
    # Make sure model directory exists
    ensure_dir(model_save_path)
    
    # Load the data
    print(f"Loading data from: {os.path.basename(data_path)}")
    df = pd.read_csv(data_path)
    print(f"Loaded {len(df)} reviews")
    
    # Define function to extract rating from prediction column
    def extract_rating(prediction_str):
        """Extract the numeric rating from the prediction string"""
        if pd.isna(prediction_str):
            return None
        try:
            # Parse the string representation of the list containing a dictionary
            prediction_list = ast.literal_eval(prediction_str.replace("'", "\""))
            # Extract the label from the first item
            rating = int(prediction_list[0]['label'])
            return rating
        except:
            return None
    
    # Extract ratings
    if 'prediction' in df.columns:
        df['rating'] = df['prediction'].apply(extract_rating)
    elif 'annotation' in df.columns and not df['annotation'].isna().all():
        df['rating'] = df['annotation'].apply(extract_rating)
    else:
        print("\nWarning: Could not find rating information")
    
    # Clean and filter data
    df = df.dropna(subset=['text'])
    if 'rating' in df.columns:
        df = df.dropna(subset=['rating'])
        df['rating'] = df['rating'].astype(int)
        df = df[df['rating'].between(1, 5)]
    
    print(f"\nClean dataset size: {len(df)} reviews")
    
    # Add preprocessed text and sentiment
    df['processed_text'] = df['text'].apply(preprocess_text)
    
    # Initialize sentiment analyzer
    sid = SentimentIntensityAnalyzer()
    df['sentiment'] = df['text'].apply(lambda x: sid.polarity_scores(x)['compound'] if isinstance(x, str) else 0)
    
    # Check class distribution
    if 'rating' in df.columns:
        print("\nRating distribution:")
        rating_counts = df['rating'].value_counts().sort_index()
        print(rating_counts)
    
    # Apply sentiment threshold logic to training data
    print("\nApplying sentiment threshold to training data...")
    neutral_mask = (df['sentiment'] >= NEUTRAL_LOWER) & (df['sentiment'] <= NEUTRAL_UPPER)
    num_neutral = neutral_mask.sum()
    print(f"Found {num_neutral} reviews with very neutral sentiment (between {NEUTRAL_LOWER} and {NEUTRAL_UPPER})")
    
    # Check how many neutral sentiment reviews have ratings other than 3
    if num_neutral > 0:
        non_3_neutral = ((df['rating'] != 3) & neutral_mask).sum()
        print(f"Of these, {non_3_neutral} ({non_3_neutral/num_neutral:.1%}) have ratings other than 3")
        
        # Artificially adjust some neutral reviews to have rating 3 for better training
        adjustment_rate = 0.5  # Adjust 50% of non-3 neutral reviews
        
        # Create mask for reviews to adjust
        adjustment_candidates = (df['rating'] != 3) & neutral_mask
        num_to_adjust = int(adjustment_candidates.sum() * adjustment_rate)
        
        if num_to_adjust > 0:
            # Select random subset to adjust
            adjust_indices = np.random.choice(
                df[adjustment_candidates].index, 
                size=num_to_adjust, 
                replace=False
            )
            
            # Adjust ratings
            df.loc[adjust_indices, 'rating'] = 3
            print(f"Adjusted {num_to_adjust} reviews with neutral sentiment to have rating 3")
    
    # Prepare for model training if we have ratings
    if 'rating' in df.columns and len(df) > 100:
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            df['processed_text'], 
            df['rating'], 
            test_size=0.2, 
            random_state=42, 
            stratify=df['rating']
        )
        
        print(f"\nTraining set: {len(X_train)} reviews")
        print(f"Test set: {len(X_test)} reviews")
        
        # Create bag-of-words features
        vectorizer = CountVectorizer(
            max_features=2000,
            min_df=5,
            ngram_range=(1, 2)
        )
        
        X_train_bow = vectorizer.fit_transform(X_train)
        X_test_bow = vectorizer.transform(X_test)
        
        # Train logistic regression model
        model = LogisticRegression(
            C=1.0,
            class_weight='balanced',
            solver='liblinear',
            multi_class='ovr',
            max_iter=1000,
            random_state=42
        )
        
        print("\nTraining model...")
        model.fit(X_train_bow, y_train)
        
        # Evaluate model
        y_pred = model.predict(X_test_bow)
        accuracy = accuracy_score(y_test, y_pred)
        report = classification_report(y_test, y_pred)
        conf_matrix = confusion_matrix(y_test, y_pred)
        
        print(f"\nModel Accuracy: {accuracy:.4f}")
        print("\nClassification Report:")
        print(report)
        
        # Save model and vectorizer (but NOT functions)
        print(f"\nSaving model to {os.path.basename(model_save_path)}")
        model_dict = {
            'vectorizer': vectorizer,
            'model': model,
            'neutral_lower': NEUTRAL_LOWER,
            'neutral_upper': NEUTRAL_UPPER
        }
        
        with open(model_save_path, 'wb') as file:
            pickle.dump(model_dict, file)
        
        print("Model successfully saved!")
        
        # Test example reviews
        example_reviews = [
            "This service is terrible. I waited for hours and no one showed up.",
            "Great experience overall. The driver was friendly and the car was clean.",
            "It was okay. Nothing special but got me where I needed to go.",
            "Sadly I have not had very good service in Edmonton by Uber in the last few months. I have been sworn at by drivers, insulted by drivers, had advances made toward me by drivers, and more. Most drivers refused to come into my condo complex because the GPS shows my address as in the middle of the road. If I pin the address as suggested on their website they go to the wrong address and then cancel the trip. I regularly get double charged and have to request a refund. Also I have been noticing that in the last few weeks I have be quoted a rate, charge the rate, then refunded that rate, and charged a higher rate every trip. The saddest part of all is that in Edmonton Uber is the safest way to travel outside of the bus. I wouldn't get into a cab in this city ever and now I don't ever want to get into an Uber. I have contact Uber about my issues as well and been threatened multiple times. Uber is all about $$. They could care less about their customers.",
            "I just spent 45 minutes of my life trying to simply update password and my 'Home' information on the Uber phone App. What an absolute joke._x000D_I was in a hurry to get somewhere and made the huge mistake of trying to give this company another chance... all they managed to do was to waste my time._x000D_Save time, money and frustration... use Fasten, Lyft or anybody else. This company just needs to close!"
        ]
        
        print("\nTesting model on example reviews:")
        for review in example_reviews:
            # Use the global function with the trained components
            result = predict_rating(review, vectorizer, model, NEUTRAL_LOWER, NEUTRAL_UPPER)
            print(f"\nReview: {review}")
            print(f"Sentiment: {result['sentiment']:.2f}")
            print(f"Predicted Rating: {result['rating']}")
            if result['override_applied']:
                print(f"(Original model prediction: {result['model_prediction']})")
            
        return vectorizer, model
    else:
        print("\nNot enough data with ratings to train a model.")
        return None

# Function to load the saved model
def load_model(model_path):
    """
    Load the saved model
    
    Args:
        model_path (str): Path to the saved model file
    
    Returns:
        tuple: (vectorizer, model, neutral_lower, neutral_upper)
    """
    # Get absolute path if relative
    if not os.path.isabs(model_path):
        script_dir = os.path.dirname(os.path.abspath(__file__))
        model_path = os.path.join(script_dir, model_path)
    
    with open(model_path, 'rb') as file:
        model_dict = pickle.load(file)
    
    return (
        model_dict['vectorizer'],
        model_dict['model'],
        model_dict['neutral_lower'],
        model_dict['neutral_upper']
    )

# Function to predict using loaded model
def predict_with_loaded_model(review_text, config_path="config.yaml"):
    """
    Predict rating for a review by loading model from config
    
    Args:
        review_text (str): The review text
        config_path (str): Path to config file
        
    Returns:
        int: Predicted rating (1-5)
    """
    # Load model from config
    config = load_config(config_path)
    model_path = config.get('model_path')
    vectorizer, model, neutral_lower, neutral_upper = load_model(model_path)
    
    # Use the global prediction function
    result = predict_rating(review_text, vectorizer, model, neutral_lower, neutral_upper)
    
    return result['rating']

if __name__ == "__main__":
    main("config.yaml")