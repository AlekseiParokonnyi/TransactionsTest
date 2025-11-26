using Newtonsoft.Json;
using Newtonsoft.Json.Converters;
using Npgsql;
using Transactions.Logic;
using Transactions.Repository;
using Transactions.Repository.Abstractions;
using Transactions.UpdateTransactionStateWorker.Options;

namespace Transactions.UpdateTransactionStateWorker;

public class Program
{
  public static async Task Main(string[] args)
  {
    var builder = Host.CreateApplicationBuilder(args);

    var connectionString = builder.Configuration.GetConnectionString("Default");
    builder.Services.AddNpgsqlDataSource(connectionString!, dataSourceBuilder =>
    {
      var jsonSettings = new JsonSerializerSettings
      {
        Converters = { new StringEnumConverter() },
        NullValueHandling = NullValueHandling.Ignore
      };

      dataSourceBuilder.UseJsonNet(jsonSettings);
    });

    builder.Services.Configure<AppOptions>(builder.Configuration.GetSection("Options"));

    builder.Services.AddSingleton<ITransactionsRepository, TransactionsRepository>();
    builder.Services.AddSingleton<ITransactionsService, TransactionsService>();

    builder.Services.AddHostedService<UpdateTransactionStateWorker>();

    var host = builder.Build();

    await host.RunAsync();
  }
}