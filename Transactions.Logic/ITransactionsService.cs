using Transactions.Core;
using Transactions.Logic.Models;

namespace Transactions.Logic;

public interface ITransactionsService
{
  Task<CreateTransactionResult> CreateTransactionAsync(Transaction transaction);
  Task<UpdateTransactionsStatesResult> UpdateTransactionsStatesByTimeAsync(int currentSeconds);
}