from src.stockdata_fetcher import StockDataFetcher

import pandas as pd


class TestStockDataFetcher:
    def test_get_stock_data(self):
        sdf = StockDataFetcher(token="test")
        data = sdf.get_stock_data(ticker="AAPL",
                                  date="2020-01-01")
        assert data.empty
        assert isinstance(data, pd.DataFrame)
