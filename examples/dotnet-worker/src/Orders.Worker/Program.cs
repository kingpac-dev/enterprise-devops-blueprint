using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Orders.Worker;

var builder = Host.CreateApplicationBuilder(args);

// ---------------------------------------------------------------------------
// Configuration — supplied at run time, never compiled in
// ---------------------------------------------------------------------------
var options = builder.Configuration
    .GetSection(WorkerOptions.SectionName)
    .Get<WorkerOptions>() ?? new WorkerOptions();

// Fails fast. A missing required value stops the container rather than
// starting in a configuration that might point at the wrong environment.
// See docs/06-container/docker-standard.md, requirement C9.
options.Validate();

builder.Services.AddSingleton(options);

// ---------------------------------------------------------------------------
// Graceful shutdown
// ---------------------------------------------------------------------------
// The .NET Generic Host default shutdown timeout is 30 seconds in recent
// versions and was 5 seconds historically. Either way it must be set
// DELIBERATELY, and it must be shorter than the container stop grace period
// — otherwise the process is killed while it still believes it has time.
//
//     application shutdown timeout  <  container stop grace period
//
// See templates/compose/compose.prod.yml (stop_grace_period)
builder.Services.Configure<HostOptions>(host =>
{
    host.ShutdownTimeout = options.ShutdownTimeout;
});

// ---------------------------------------------------------------------------
// Logging — stdout, structured, no credentials
// ---------------------------------------------------------------------------
builder.Logging.ClearProviders();
builder.Logging.AddSimpleConsole(console =>
{
    console.TimestampFormat = "yyyy-MM-ddTHH:mm:ss.fffZ ";
    console.UseUtcTimestamp = true;
});

// ---------------------------------------------------------------------------
// Services
// ---------------------------------------------------------------------------
builder.Services.AddSingleton(TimeProvider.System);
builder.Services.AddSingleton<ILivenessSignal>(sp =>
    new FileLivenessSignal(options.LivenessFile, sp.GetRequiredService<TimeProvider>()));
builder.Services.AddSingleton<IItemSource, StubItemSource>();
builder.Services.AddHostedService<QueueProcessor>();

var host = builder.Build();
await host.RunAsync();

/// <summary>
/// Stand-in for a real queue. Deliberately trivial: this example exists to
/// demonstrate the delivery pattern, not a broker integration.
/// </summary>
internal sealed class StubItemSource : IItemSource
{
    private readonly ILogger<StubItemSource> _logger;

    public StubItemSource(ILogger<StubItemSource> logger) => _logger = logger;

    public Task<IReadOnlyList<string>> FetchAsync(CancellationToken cancellationToken)
        => Task.FromResult<IReadOnlyList<string>>(Array.Empty<string>());

    public Task ProcessAsync(string item, CancellationToken cancellationToken)
    {
        _logger.LogInformation("{Event} Processed {Item}", "worker_item_processed", item);
        return Task.CompletedTask;
    }
}
