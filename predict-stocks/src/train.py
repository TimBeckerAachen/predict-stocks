import mlflow
import numpy as np
from typing import Tuple
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error

from DataFetcher import DataFetcher


mlflow.set_tracking_uri("http://0.0.0.0:5000")
mlflow.set_experiment('stock-prediction')
mlflow.sklearn.autolog()


def preprocess_data(prices: np.array) -> Tuple[np.array, np.array]:
    """
    Preprocesses the data to create feature and target sets.

    Args:
    - prices: A numpy array with opening and closing prices for 30 days.

    Returns:
    - X: Feature set where each row represents the opening and closing price of a day.
    - y: Target set where each entry represents the closing price of the next day.
    """
    X = prices[:-1]
    y = prices[1:, 1]

    return X, y


def train_model(X: np.array, y: np.array) -> None:
    """
    Trains a random forest regressor using the given feature and target sets.

    Args:
    - X: Feature set.
    - y: Target set.

    Returns:
    - model: Trained Random Forest Regressor.
    """
    X_train, X_val, y_train, y_val = train_test_split(X, y, test_size=0.2, random_state=0)

    with mlflow.start_run():
        rf = RandomForestRegressor(n_estimators=10, random_state=0)
        rf.fit(X_train, y_train)
        y_pred = rf.predict(X_val)

        mse = mean_squared_error(y_val, y_pred, squared=False)
        mlflow.log_metric("mse", mse)

        mlflow.log_param("n_estimators", 10)
        mlflow.log_param("random_state", 0)

        mlflow.sklearn.log_model(rf, "model")
    print('model trained')


def train():
    ticker = "IBM"
    fetcher = DataFetcher()
    stock_data = fetcher.fetch_last_30_days_prices(ticker)
    X, y = preprocess_data(stock_data)
    train_model(X, y)


if __name__ == "__main__":
    train()
