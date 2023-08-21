import yfinance as yf
from datetime import datetime, timedelta
import numpy as np


class DataFetcher:
    @staticmethod
    def fetch_latest_prices(ticker: str) -> np.array:
        """
        Fetches the opening and closing prices of the latest day the stock market was open.

        Args:
        - ticker: The stock identifier.

        Returns:
        - A numpy array containing the opening and closing prices.
        """
        days_back = 2
        while days_back < 5:
            yesterday = (datetime.now() - timedelta(days=1)).strftime('%Y-%m-%d')
            previous_day_with_stock_trading = (datetime.now() - timedelta(days=days_back)).strftime('%Y-%m-%d')
            data = yf.download(ticker, start=previous_day_with_stock_trading, end=yesterday)

            if not data.empty:
                break
            days_back += 1
        else:
            raise ValueError(f"No stock data found for the last {days_back}!")

        return np.array([data['Open'][-1], data['Close'][-1]])

    @staticmethod
    def fetch_last_30_days_prices(ticker: str) -> np.array:
        """
        Fetches the opening and closing prices for the last 30 days the stock market was open.

        Args:
        - ticker: The stock identifier.

        Returns:
        - A numpy array where each row contains opening and closing prices for a day.
        """
        end_date = datetime.now()
        start_date = end_date - timedelta(days=50)
        data = yf.download(ticker, start=start_date.strftime('%Y-%m-%d'), end=end_date.strftime('%Y-%m-%d'))

        if data.empty:
            raise ValueError("Data for the last 30 days is not available. Check the ticker or try later.")

        return np.column_stack((data['Open'].values, data['Close'].values))[-30:]


if __name__ == "__main__":
    fetcher = DataFetcher()
    print(fetcher.fetch_latest_prices("IBM"))
    print(fetcher.fetch_last_30_days_prices("IBM"))
