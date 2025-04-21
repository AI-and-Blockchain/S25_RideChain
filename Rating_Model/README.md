# Driver Review Rating Model
This project implements a text-based rating system that automatically scores driver reviews on a scale of 1-5 stars using machine learning and sentiment analysis. The system processes textual feedback from riders to generate numerical ratings that directly impact driver reputation on the RideChain platform.

---

## Table of Contents
- [Overview](#overview)
- [Project Structure](#project-structure)
- [How To Use](#how-to-use)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Dataset Setup](#dataset-setup)
  - [Training the Model](#training-the-model)
  - [Using the Model](#using-the-model)
- [Model Architecture](#model-architecture)
- [License](#license)

---

## Overview

This system builds a natural language processing pipeline that converts textual ride reviews into numerical scores (1-5 stars). It combines a trained machine learning model with sentiment analysis to ensure accurate and consistent driver ratings.

### Components:
- **Text Preprocessing**: Normalizes review text by removing special characters and standardizing format
- **Feature Extraction**: Converts text to bag-of-words features with n-gram support
- **Sentiment Analysis**: Uses VADER to capture emotional tone in reviews
- **ML Classification**: Employs a logistic regression model to predict star ratings
- **Rule-Based Overrides**: Applies sentiment thresholds to handle edge cases

---

## Project Structure
Rating_Model/
├── Data/
│   └── converted_train.csv  # Training dataset with reviews and ratings
├── Model/
│   └── driver_rating_model.pkl  # Serialized model file
├── README.md
├── config.yaml  # Configuration settings
├── requirements.txt
├── single_review_score.py  # Inference script for scoring individual reviews
└── training_model.py  # Model training pipeline

---

## How To Use

### Prerequisites
- Python 3.8+
- Required Python libraries: `pandas`, `scikit-learn`, `nltk`, `pyyaml`

### Installation
git clone https://github.com/your-username/driver-rating-model.git
cd driver-rating-model
pip install -r requirements.txt
python -m nltk.downloader vader_lexicon
Dataset Setup
This project uses the argilla/uber-reviews dataset from HuggingFace, which contains over 2,300 annotated rider reviews with corresponding star ratings.

Download the dataset:
bash# Using the HuggingFace datasets library
python -c "from datasets import load_dataset; dataset = load_dataset('argilla/uber-reviews'); dataset['train'].to_csv('Data/converted_train.csv')"
Alternatively, you can download it manually from: https://huggingface.co/datasets/argilla/uber-reviews
Ensure the CSV file is placed in the Data/ directory.

Training the Model
To train the model with default parameters:
bashpython training_model.py
This will:

Load and preprocess the review dataset
Extract text features using bag-of-words
Calculate sentiment scores
Train a logistic regression classifier
Apply sentiment threshold rules
Save the model to Model/driver_rating_model.pkl

Using the Model
To score a new review:
pythonfrom single_review_score import get_review_score

# Score a single review
review = "The driver was friendly and the car was clean."
rating = get_review_score(review)
print(f"Predicted Rating: {rating}")

Model Architecture
The rating system uses a hybrid approach combining:

Text Preprocessing: Converts text to lowercase and removes special characters
Feature Extraction: Uses CountVectorizer with n-gram features (1-2)
Sentiment Analysis: VADER SentimentIntensityAnalyzer to capture emotional tone
Classification: Logistic regression with class balancing
Rule-Based Overrides:

Very neutral reviews (sentiment -0.1 to 0.1) → Rating 3
Very positive reviews (sentiment > 0.7) → Minimum rating 4
Very negative reviews (sentiment < -0.7) → Maximum rating 2

This combined approach ensures more accurate and consistent ratings than relying on machine learning or sentiment analysis alone.

License
MIT License
