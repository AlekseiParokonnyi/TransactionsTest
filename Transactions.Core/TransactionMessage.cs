namespace Transactions.Core;

public record TransactionMessage
{
  public long AccountId { get; init; }
  public long ClientId { get; init; }
  public TransactionType Type { get; init; }
}