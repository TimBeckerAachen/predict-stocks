import httpx
import logging
import pandas as pd
# TODO: create interface -> use all options

logger = logging.getLogger(__name__)


class StockDataFetcher:
    def __init__(self, token: str) -> None:
        self.base_url = 'https://api.stockdata.org/v1/data/intraday'
        self.token = token

    def get_stock_data(self, ticker: str, date: str, interval: str = 'minute') -> pd.DataFrame:
        params = {
            'symbols': ticker,
            'interval': interval,
            'date': date, # TODO: allow any and parse, handle None -> docs
            'api_token': self.token
        }

        resp = httpx.get(self.base_url, params=params)
        if resp.status_code == 200:
            stock_data = pd.DataFrame.from_records(resp.json()['data'])
            stock_data = stock_data.join(pd.DataFrame(stock_data.pop('data').tolist()))
        else:
            logger.warning(f'No data retrieved for params: {params}')
            stock_data = pd.DataFrame()
        return stock_data


if __name__ == '__main__':
    from dotenv import load_dotenv
    import os

    load_dotenv()

    TOKEN = os.getenv('STOCKDATA_API_KEY')

    sd = StockDataFetcher(TOKEN)
    data = sd.get_stock_data('IBM',
                             '2023-08-01')
    print(data.head())
