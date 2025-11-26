using Newtonsoft.Json;
using Newtonsoft.Json.Converters;
using Npgsql;
using Transactions.CreateTransactionWorker.Options;
using Transactions.Logic;
using Transactions.Repository;
using Transactions.Repository.Abstractions;

namespace Transactions.CreateTransactionWorker;

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

    builder.Services.AddHostedService<CreateTransactionWorker>();

    var host = builder.Build();

    await host.RunAsync();
  }
}