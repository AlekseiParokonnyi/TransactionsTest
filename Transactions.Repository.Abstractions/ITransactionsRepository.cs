using Transactions.Core;

namespace Transactions.Repository.Abstractions;

public interface ITransactionsRepository
{
  Task<long> InsertAsync(Transaction transaction);
  Task UpdateStatesByConditionAsync(TransactionState targetState, TransactionState currentState, bool updateEvenIds);
}