CREATE SUBSCRIPTION transactions_sub
CONNECTION 'host=postgres_dev port=5432 dbname=TransactionsDB user=postgres password=123456Q!'
PUBLICATION transactions_pub;