using System.Data;
using Npgsql;
using NpgsqlTypes;
using Transactions.Core;
using Transactions.Repository.Abstractions;
using Transactions.Repository.Abstractions.Models;

namespace Transactions.Repository;

public class TransactionsRepository : ITransactionsRepository
{
  private readonly NpgsqlDataSource _dataSource;

  public TransactionsRepository(NpgsqlDataSource dataSource)
  {
    _dataSource = dataSource;
  }

  public async Task<long> InsertAsync(Transaction transaction)
  {
    await using var connection = await _dataSource.OpenConnectionAsync();

    await using var command = new NpgsqlCommand("sp_insert_transaction", connection)
    {
      CommandType = CommandType.StoredProcedure
    };

    command.Parameters.AddWithValue("p_datetime", NpgsqlDbType.TimestampTz, transaction.DateTime);
    command.Parameters.AddWithValue("p_amount", transaction.Amount);
    command.Parameters.AddWithValue("p_state", (int)transaction.State);
    command.Parameters.AddWithValue("p_operation_guid", transaction.OperationGuid);
    command.Parameters.AddWithValue("p_message", NpgsqlDbType.Jsonb, new DbTransactionMessage
    {
      ClientId = transaction.Message.ClientId,
      AccountId = transaction.Message.AccountId,
      Type = transaction.Message.Type.ToString().ToLower()
    });

    var idParam = new NpgsqlParameter("p_id", DbType.Int64) { Direction = ParameterDirection.Output };
    command.Parameters.Add(idParam);

    await command.ExecuteNonQueryAsync();

    return (long)idParam.Value!;
  }

  public async Task UpdateStatesByConditionAsync(TransactionState targetState, TransactionState currentState, bool updateEvenIds)
  {
    await using var connection = await _dataSource.OpenConnectionAsync();
    await using var command = new NpgsqlCommand("sp_update_transactions_states", connection)
    {
      CommandType = CommandType.StoredProcedure
    };

    command.Parameters.AddWithValue("p_target_state", (int)targetState);
    command.Parameters.AddWithValue("p_current_state", (int)currentState);
    command.Parameters.AddWithValue("p_update_even_ids", updateEvenIds);

    await command.ExecuteNonQueryAsync();
  }
}
