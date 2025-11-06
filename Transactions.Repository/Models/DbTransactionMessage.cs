using Newtonsoft.Json;

namespace Transactions.Repository.Models;

public class DbTransactionMessage
{
  [JsonProperty("accountId")]
  public long AccountId { get; init; }

  [JsonProperty("clientId")]
  public long ClientId { get; init; }

  [JsonProperty("operationType")]
  public string Type { get; init; }
}