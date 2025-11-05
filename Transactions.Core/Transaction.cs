namespace Transactions.Core;

public record Transaction
{
  public long Id { get; init; }
  public DateTime DateTime { get; init; }
  public decimal Amount { get; init; }
  public TransactionState State { get; set; }
  public Guid OperationGuid { get; init; }
  public TransactionMessage Message { get; init; }
}
