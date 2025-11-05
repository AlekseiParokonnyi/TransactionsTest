using Transactions.Core;
using Transactions.Logic.Models;
using Transactions.Repository.Abstractions;

namespace Transactions.Logic;

public class TransactionsService : ITransactionsService
{
  private readonly ITransactionsRepository _transactionsRepository;

  public TransactionsService(ITransactionsRepository transactionsRepository)
  {
    _transactionsRepository = transactionsRepository;
  }

  public async Task<CreateTransactionResult> CreateTransactionAsync(Transaction transaction)
  {
    var id = await _transactionsRepository.InsertAsync(transaction);
    return new CreateTransactionResult { Id = id };
  }

  public async Task<UpdateTransactionsStatesResult> UpdateTransactionsStatesByTimeAsync(int currentSeconds)
  {
    var isEvenUpdate = currentSeconds % 2 == 0;

    await _transactionsRepository.UpdateStatesByConditionAsync(TransactionState.Processed, TransactionState.Pending, isEvenUpdate);

    return new UpdateTransactionsStatesResult { IsEvenUpdate = isEvenUpdate };
  }
}