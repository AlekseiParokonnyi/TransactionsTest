using System.Reflection;
using Microsoft.Extensions.Configuration;
using DbUp;
using DbUp.Engine;
using DbUp.Support;
using Npgsql;

var config = new ConfigurationBuilder()
  .SetBasePath(Directory.GetCurrentDirectory())
  .AddJsonFile("appsettings.json", optional: true)
  .Build();

var connectionString = args.FirstOrDefault()
                       ?? config.GetConnectionString("Default");

EnsureDatabaseExists(connectionString);

var upgrader = DeployChanges.To
  .PostgresqlDatabase(connectionString)
  .WithScriptsEmbeddedInAssembly(Assembly.GetExecutingAssembly(),
    script => script.Contains("Schemas"),
    new SqlScriptOptions
    {
      ScriptType = ScriptType.RunOnce,
      RunGroupOrder = 1
    })
  .WithScriptsEmbeddedInAssembly(Assembly.GetExecutingAssembly(),
    script => script.Contains("Tables"),
    new SqlScriptOptions
    {
      ScriptType = ScriptType.RunOnce,
      RunGroupOrder = 2
    })
  .WithScriptsEmbeddedInAssembly(Assembly.GetExecutingAssembly(),
    script => script.Contains("Views"),
    new SqlScriptOptions
    {
      ScriptType = ScriptType.RunOnce,
      RunGroupOrder = 3
    })
  .WithScriptsEmbeddedInAssembly(Assembly.GetExecutingAssembly(),
    script => script.Contains("Functions"),
    new SqlScriptOptions
    {
      ScriptType = ScriptType.RunAlways,
      RunGroupOrder = 4
    })
  .WithScriptsEmbeddedInAssembly(Assembly.GetExecutingAssembly(),
    script => script.Contains("StoredProcedures"),
    new SqlScriptOptions
    {
      ScriptType = ScriptType.RunAlways,
      RunGroupOrder = 5
    })
  .WithScriptsEmbeddedInAssembly(Assembly.GetExecutingAssembly(),
    script => script.Contains("Triggers"),
    new SqlScriptOptions
    {
      ScriptType = ScriptType.RunOnce,
      RunGroupOrder = 6
    })
  .WithScriptsEmbeddedInAssembly(Assembly.GetExecutingAssembly(),
    script => script.Contains("ReplicationPrimary"),
    new SqlScriptOptions
    {
      ScriptType = ScriptType.RunOnce,
      RunGroupOrder = 7
    })
  .WithScriptsEmbeddedInAssembly(Assembly.GetExecutingAssembly(),
    script => script.Contains("Deployment"),
    new SqlScriptOptions
    {
      ScriptType = ScriptType.RunAlways,
      RunGroupOrder = 8
    })
  .LogToConsole()
  .Build();

var result = upgrader.PerformUpgrade();

// Display the result
if (result.Successful)
{
  Console.ForegroundColor = ConsoleColor.Green;
  Console.WriteLine("Success!");
}
else
{
  Console.ForegroundColor = ConsoleColor.Red;
  Console.WriteLine(result.Error);
  Console.WriteLine("Failed!");
}

Console.ForegroundColor = ConsoleColor.White;

static void EnsureDatabaseExists(string connectionString)
{
  var builder = new NpgsqlConnectionStringBuilder(connectionString);
  var dbName = builder.Database;

  builder.Database = "postgres";

  using var conn = new NpgsqlConnection(builder.ConnectionString);
  conn.Open();
  using var cmd = new NpgsqlCommand(
    $"SELECT 1 FROM pg_database WHERE datname = '{dbName}'",
    conn);

  var exists = cmd.ExecuteScalar() != null;
  if (!exists)
  {
    Console.WriteLine($"Database '{dbName}' not found — creating");
    using var create = new NpgsqlCommand($"CREATE DATABASE \"{dbName}\";", conn);
    create.ExecuteNonQuery();
    Console.WriteLine($"Database '{dbName}' created");
  }
}
