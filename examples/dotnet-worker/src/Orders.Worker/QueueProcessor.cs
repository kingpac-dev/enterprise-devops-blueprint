using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Orders.Worker;

/// <summary>
/// The blueprint-relevant parts of a worker: graceful shutdown, and a
/// liveness signal that reflects WORK rather than process existence.
///
/// The "queue" here is a stub. This example demonstrates the delivery
/// pattern, not a message broker integration.
/// </summary>
public sealed class QueueProcessor : BackgroundService
{
    private readonly WorkerOptions _options;
    private readonly ILivenessSignal _liveness;
    private readonly IItemSource _source;
    private readonly ILogger<QueueProcessor> _logger;

    public QueueProcessor(
        WorkerOptions options,
        ILivenessSignal liveness,
        IItemSource source,
        ILogger<QueueProcessor> logger)
    {
        _options = options;
        _liveness = liveness;
        _source = source;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        // Structured logging with a stable `event` name. The message text can
        // be improved later without breaking queries written against it.
        // See docs/08-observability/logging-standard.md
        _logger.LogInformation("{Event} Worker started", "worker_started");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessOneCycleAsync(stoppingToken).ConfigureAwait(false);

                // Recorded ONLY after a successful cycle. Recording it at the
                // top of the loop would report liveness for a worker that is
                // looping and failing — which is the exact failure this
                // signal exists to detect.
                _liveness.RecordSuccess();
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                // Shutdown requested mid-cycle. Expected; not an error.
                break;
            }
            catch (Exception ex)
            {
                // A failed cycle does NOT record liveness. If failures
                // persist, the liveness file goes stale and the container
                // health check fails — which is correct: the worker is
                // running and not working.
                _logger.LogError(ex, "{Event} Processing cycle failed", "worker_cycle_failed");
            }

            try
            {
                await Task.Delay(_options.PollInterval, stoppingToken).ConfigureAwait(false);
            }
            catch (OperationCanceledException)
            {
                break;
            }
        }

        _logger.LogInformation("{Event} Worker stopping", "worker_stopping");
    }

    private async Task ProcessOneCycleAsync(CancellationToken stoppingToken)
    {
        var items = await _source.FetchAsync(stoppingToken).ConfigureAwait(false);

        foreach (var item in items)
        {
            // Checked between items, not within one. An item that has started
            // is finished — abandoning it mid-way can leave a partial write or
            // an unacknowledged message, which is the difference between a
            // clean deployment and a data-integrity incident.
            //
            // This is why ShutdownTimeout must exceed MaxItemDuration; see
            // WorkerOptions.Validate().
            if (stoppingToken.IsCancellationRequested)
            {
                _logger.LogInformation(
                    "{Event} Shutdown requested; stopping between items", "worker_shutdown_between_items");
                return;
            }

            await _source.ProcessAsync(item, CancellationToken.None).ConfigureAwait(false);
        }
    }
}

/// <summary>Stub source. A real implementation would consume a queue.</summary>
public interface IItemSource
{
    Task<IReadOnlyList<string>> FetchAsync(CancellationToken cancellationToken);

    Task ProcessAsync(string item, CancellationToken cancellationToken);
}
