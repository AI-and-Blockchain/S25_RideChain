# Driver Performance Rating Analysis

This project analyzes ride-sharing data to generate driver performance ratings using ride event logs, ride characteristics, and onboarding information. It applies data cleaning, feature engineering, and machine learning to create an automated, scalable driver evaluation system.

---

## Table of Contents

- [Overview](#overview)
- [How To Use](#how-to-use)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Dataset Setup](#dataset-setup)
  - [Running the Notebook](#running-the-notebook)
- [Features](#features)
- [License](#license)

---

## Overview

This system builds a full data pipeline from raw CSVs to predictive modeling, with the goal of classifying drivers into performance tiers — **Poor**, **Average**, **Good**, and **Excellent** — based on historical ride data.

### Components:
- **Data Loading & Merging**: Integrates three raw data sources into one clean dataset.
- **Feature Engineering**: Extracts metrics like accept delay, trip duration, prime time usage, and ride completion.
- **Driver Labeling**: Assigns ratings based on thresholds or rules.
- **Model Training**: Trains a multi-class classifier to predict driver ratings using labeled data.

---

## How To Use

### Prerequisites

- Python 3.8+
- Jupyter Notebook
- Recommended Python libraries: `pandas`, `scikit-learn`, `xgboost`, `pyyaml`

### Installation

```bash
git clone https://github.com/your-username/driver-rating-project.git
cd driver-rating-project
pip install -r requirements.txt
```

---

### Dataset Setup

This project uses data from the [Lyft Rides Analysis repository](https://github.com/kevinchen27/lyft-rides-analysis) by [@kevinchen27](https://github.com/kevinchen27).

To run the notebook, follow these steps:

1. Visit the dataset source:  
   https://github.com/kevinchen27/lyft-rides-analysis

2. Download the following files from the `data/` folder:
   - `driver_ids.csv`
   - `ride_ids.csv`
   - `ride_timestamps.csv`

3. Create a folder named `Data/` in the root of this project and place the CSV files inside it:

```
driver-rating-project/
├── Data/
│   ├── driver_ids.csv
│   ├── ride_ids.csv
│   └── ride_timestamps.csv
├── rating.ipynb
├── config.yaml
├── requirements.txt
└── README.md
```

> **Note**: This dataset is provided by a third party. Please review their README and terms of use before redistributing or using it in production.

---

### Running the Notebook

Once the dataset is in place, run:

```bash
jupyter notebook rating.ipynb
```

The notebook will walk through data preprocessing, feature generation, driver labeling, and model training.

---

## Features

- **Feature Engineering**:
  - Average trip duration  
  - Ride completion rate  
  - Accept delay  
  - Prime time utilization

- **Driver Labeling**:
  - Classifies drivers into performance tiers: *Poor*, *Average*, *Good*, *Excellent*

- **Model Training**:
  - Supports models like XGBoost, Random Forest, and Logistic Regression

- **Evaluation Metrics**:
  - Accuracy  
  - F1-score  
  - Confusion matrix

- **Predictions**:
  - Predicts new driver ratings without hardcoded rules

---

## License

MIT License

