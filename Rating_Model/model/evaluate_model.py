'''Load and Merge the Dataset'''

import pandas as pd
import yaml

# Load config
with open("config.yaml", "r") as f:
    config = yaml.safe_load(f)

# Load data using config paths
df_drivers = pd.read_csv(config['data_paths']['driver_ids'])
df_rides = pd.read_csv(config['data_paths']['ride_ids'])
df_timestamps = pd.read_csv(config['data_paths']['ride_timestamps'])


# Pivot the timestamp events to wide format: one row per ride_id with columns for each event
df_events = df_timestamps.pivot(index='ride_id', columns='event', values='timestamp').reset_index()

# Convert timestamp columns to datetime
for col in ['requested', 'accepted', 'completed']:
    if col in df_events.columns:
        df_events[col] = pd.to_datetime(df_events[col])

# Joining data on ride_id to obtain per-ride data

# Join ride data with event timestamps
df_combined = pd.merge(df_rides, df_events, on='ride_id', how='inner')

# Join driver info (e.g., onboarding date)
df_combined = pd.merge(df_combined, df_drivers, on='driver_id', how='left')

# Compute accept delay (seconds)
df_combined['accept_delay'] = (pd.to_datetime(df_combined['accepted_at']) - pd.to_datetime(df_combined['requested_at'])).dt.total_seconds()

# Compute completion flag: 1 if the ride was dropped off
df_combined['completed_flag'] = df_combined['dropped_off_at'].notnull().astype(int)

import numpy as np
from sklearn.model_selection import train_test_split
from xgboost import XGBClassifier
from sklearn.metrics import classification_report, confusion_matrix
import joblib

# Clean and process prime_time if it's a string like "50%"
if df_combined['ride_prime_time'].dtype == object:
    df_combined['ride_prime_time'] = df_combined['ride_prime_time'].str.rstrip('%').astype(float) / 100

# Create binary prime_time_flag
df_combined['prime_time_flag'] = (df_combined['ride_prime_time'] > 0).astype(int)

# Drop any rows missing key values
df_filtered = df_combined.dropna(subset=['accept_delay', 'ride_duration'])

# Group by driver to get performance features
driver_stats = df_filtered.groupby('driver_id').agg({
    'accept_delay': 'mean',
    'ride_duration': 'mean',
    'prime_time_flag': 'mean',
    'ride_id': 'count'
}).reset_index()

driver_stats.rename(columns={
    'accept_delay': 'accept_delay_avg',
    'ride_duration': 'avg_duration',
    'prime_time_flag': 'prime_time_ratio',
    'ride_id': 'ride_count'
}, inplace=True)

# Label drivers
def label_driver(row):
    if row['ride_count'] < 10 or row['accept_delay_avg'] > 120:
        return 0  # Poor
    elif row['accept_delay_avg'] > 60 or row['prime_time_ratio'] < 0.1:
        return 1  # Average
    elif row['accept_delay_avg'] <= 60 and row['prime_time_ratio'] >= 0.1:
        return 2  # Good
    else:
        return 3  # Excellent

driver_stats['rating_label'] = driver_stats.apply(label_driver, axis=1)

# Train-test split
X = driver_stats[['accept_delay_avg', 'avg_duration', 'prime_time_ratio', 'ride_count']]
y = driver_stats['rating_label']

X_train, X_test, y_train, y_test = train_test_split(X, y, stratify=y, test_size=0.2, random_state=42)

# Train XGBoost model
model = XGBClassifier(objective='multi:softmax', num_class=4, max_depth=4, n_estimators=100, learning_rate=0.1)
model.fit(X_train, y_train)

# Predict and evaluate
y_pred = model.predict(X_test)
print("Classification Report:")
print(classification_report(y_test, y_pred))
print("Confusion Matrix:")
print(confusion_matrix(y_test, y_pred))

# Save the model
joblib.dump(model, "model/driver_rating_model.pkl")