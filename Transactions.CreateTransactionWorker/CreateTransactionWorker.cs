using Microsoft.Extensions.Options;
using Transactions.Core;
using Transactions.CreateTransactionWorker.Options;
using Transactions.Logic;

namespace Transactions.CreateTransactionWorker
{
  public class CreateTransactionWorker : BackgroundService
  {
    private readonly ITransactionsService _transactionService;
    private readonly AppOptions _appOptions;
    private readonly ILogger<CreateTransactionWorker> _logger;

    public CreateTransactionWorker(ITransactionsService transactionService, IOptions<AppOptions> appOptions, ILogger<CreateTransactionWorker> logger)
    {
      _transactionService = transactionService;
      _appOptions = appOptions.Value;
      _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
      if (_logger.IsEnabled(LogLevel.Information))
      {
        _logger.LogInformation("Worker {name} running at: {time}", nameof(CreateTransactionWorker), DateTimeOffset.Now);
      }

      while (!stoppingToken.IsCancellationRequested)
      {
        var random = new Random();

        try
        {
          await _transactionService.CreateTransactionAsync(new Transaction
          {
            DateTime = DateTime.UtcNow,
            OperationGuid = Guid.NewGuid(),
            Amount = Math.Round((decimal)random.NextDouble() * 10000, 2),
            State = TransactionState.Pending,
            Message = new TransactionMessage
            {
              ClientId = random.Next(0, 10_000),
              AccountId = random.Next(0, 1_000_000),
              Type = random.NextDouble() < 0.5 ? TransactionType.Online : TransactionType.Offline
            }
          });

          _logger.LogInformation("Transaction created at: {time}", DateTimeOffset.Now);
        }
        catch (Exception ex)
        {
          //Maybe add proper error handling
          _logger.LogError(ex, "An error occurred on transaction creation");
        }

        await Task.Delay(TimeSpan.FromSeconds(_appOptions.CreateTransactionWorkerDelay), stoppingToken);
      }
    }
  }
}
