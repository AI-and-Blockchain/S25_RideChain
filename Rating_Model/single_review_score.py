import pickle
import os
import nltk
from nltk.sentiment.vader import SentimentIntensityAnalyzer

try:
    nltk.data.find('vader_lexicon')
except LookupError:
    nltk.download('vader_lexicon')

def preprocess_text(text):
    """Basic text preprocessing"""
    import re
    if not isinstance(text, str):
        return ""
    text = text.lower()
    text = re.sub(r'[^a-z0-9\s]', ' ', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text

def get_review_score(review_text, model_path="Model/driver_rating_model.pkl"):
    """
    Simple function to score a review text on a scale of 1-5
    
    Args:
        review_text (str): The review text to score
        model_path (str): Path to the saved model file
        
    Returns:
        int: The predicted rating (1-5)
    """
    # Make path absolute if relative
    if not os.path.isabs(model_path):
        script_dir = os.path.dirname(os.path.abspath(__file__))
        model_path = os.path.join(script_dir, model_path)
    
    # Load the model
    with open(model_path, 'rb') as file:
        model_dict = pickle.load(file)
    
    vectorizer = model_dict['vectorizer']
    model = model_dict['model']
    neutral_lower = model_dict['neutral_lower']
    neutral_upper = model_dict['neutral_upper']
    
    sid = SentimentIntensityAnalyzer()
    processed = preprocess_text(review_text)
    sentiment = sid.polarity_scores(review_text)['compound']
    features = vectorizer.transform([processed])
    model_prediction = model.predict(features)[0]
    
    # Apply sentiment threshold rule
    if neutral_lower <= sentiment <= neutral_upper:
        return 3
    elif sentiment > 0.7 and model_prediction < 4:
        return max(model_prediction, 4)
    elif sentiment < -0.7 and model_prediction > 2:
        return min(model_prediction, 2)
    
    return model_prediction

# Example usage
if __name__ == "__main__":
    # Test with some example reviews
    examples = [
        "This service is terrible. I waited for hours and no one showed up.",
        "Great experience overall. The driver was friendly and the car was clean.",
        "It was okay. Nothing special but got me where I needed to go."
    ]
    
    for example in examples:
        score = get_review_score(example)
        print(f"Review: {example}")
        print(f"Score: {score}\n")