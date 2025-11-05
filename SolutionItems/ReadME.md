1. Open the solution directory.

2. Start two PostgreSQL instances using Docker:
Execute the following command:
```
docker compose up
```
in ../SolutionItems folder

3. Deploy the database. Run command below from solution root folder:
```
dotnet run --project Transactions.CreateTransactionWorker
```

4. Execute the stored procedures on postgres_dev instance of TransactionDB to generate a test data:
```
call mock_generate_transactions_data(100000);
```

5. Execute scripts:
- ReplicationSecondary_Structure.sql
- ReplicationSecondary_Subscription.sql
on postgres_replica instance of TransactionDB to setup logical replication.

6. Run the CreateTransactionWorker from solution root folder:
```
dotnet run --project Transactions.CreateTransactionWorker
```

7. Run the Transactions.UpdateTransactionStateWorker from solution root folder:
```
dotnet run --project Transactions.UpdateTransactionStateWorker
```
