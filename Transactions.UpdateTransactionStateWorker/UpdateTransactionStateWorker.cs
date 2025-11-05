using Microsoft.Extensions.Options;
using Transactions.Logic;
using Transactions.UpdateTransactionStateWorker.Options;

namespace Transactions.UpdateTransactionStateWorker
{
  public class UpdateTransactionStateWorker : BackgroundService
  {
    private readonly ITransactionsService _transactionService;
    private readonly AppOptions _appOptions;
    private readonly ILogger<UpdateTransactionStateWorker> _logger;

    public UpdateTransactionStateWorker(ITransactionsService transactionService, IOptions<AppOptions> appOptions, ILogger<UpdateTransactionStateWorker> logger)
    {
      _transactionService = transactionService;
      _appOptions = appOptions.Value;
      _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
      if (_logger.IsEnabled(LogLevel.Information))
      {
        _logger.LogInformation("Worker {name} running at: {time}", nameof(UpdateTransactionStateWorker), DateTimeOffset.Now);
      }

      while (!stoppingToken.IsCancellationRequested)
      {
        try
        {
          var currentSecond = DateTime.UtcNow.Second;
          var result = await _transactionService.UpdateTransactionsStatesByTimeAsync(currentSecond);

          _logger.LogInformation("{isEvenUpdate} transactions states updated at: {time}", result.IsEvenUpdate ? "Even" : "Odd", DateTimeOffset.Now);
        }
        catch (Exception ex)
        {
          //Maybe add proper error handling
          _logger.LogError(ex, "An error occurred on updating transactions states");
        }

        await Task.Delay(TimeSpan.FromSeconds(_appOptions.UpdateTransactionStateWorkerDelay), stoppingToken);
      }
    }
  }
}
