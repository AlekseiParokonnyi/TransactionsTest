CREATE SUBSCRIPTION transactions_sub
CONNECTION 'host=postgres_dev port=5432 dbname=TransactionsDB user=replica_user password=123456Q!2'
PUBLICATION transactions_pub;