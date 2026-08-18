using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace Orders.Api;

/// <summary>
/// Health check tags. Liveness and readiness are SEPARATE sets, and keeping
/// them separate is the point of this example.
/// </summary>
public static class HealthTags
{
    /// <summary>
    /// "Is this process healthy enough to keep running?"
    ///
    /// MUST NOT check dependencies. If liveness queries the database, a slow
    /// database fails every instance's liveness probe — so every container
    /// restarts, repeatedly, adding connection churn to a dependency already
    /// under strain, and fixing nothing. The outage is amplified by the
    /// mechanism meant to protect against it.
    /// </summary>
    public const string Live = "live";

    /// <summary>
    /// "Can it accept traffic right now?"
    ///
    /// MAY check dependencies. On failure, stop routing traffic — do NOT
    /// restart. This is what a deployment polls to decide whether the
    /// deployment succeeded.
    /// </summary>
    public const string Ready = "ready";
}

/// <summary>
/// Liveness: answers a question about THIS PROCESS only.
///
/// If the process is running and not deadlocked, it is live — even when
/// everything it depends on is broken.
/// </summary>
public sealed class ProcessHealthCheck : IHealthCheck
{
    public Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context, CancellationToken cancellationToken = default)
        => Task.FromResult(HealthCheckResult.Healthy());
}

/// <summary>
/// Readiness: a dependency check.
///
/// Stubbed here — a real implementation would perform a cheap connectivity
/// check, not a full query. A readiness endpoint polled every few seconds
/// that runs an expensive query becomes load on the dependency it is
/// checking.
/// </summary>
public sealed class DependencyHealthCheck : IHealthCheck
{
    private readonly Func<CancellationToken, Task<bool>> _probe;

    public DependencyHealthCheck(Func<CancellationToken, Task<bool>> probe) => _probe = probe;

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context, CancellationToken cancellationToken = default)
    {
        try
        {
            var ok = await _probe(cancellationToken).ConfigureAwait(false);

            // NOTE the absence of detail. The description says what failed in
            // the broadest terms and nothing more — no connection string, no
            // hostname, no exception message. A health endpoint is frequently
            // the least protected route in a service.
            return ok
                ? HealthCheckResult.Healthy()
                : HealthCheckResult.Unhealthy("dependency unavailable");
        }
        catch (Exception)
        {
            // The exception is deliberately NOT included. Exception messages
            // routinely carry connection strings and internal hostnames, and
            // this response may be readable from further away than intended.
            return HealthCheckResult.Unhealthy("dependency unavailable");
        }
    }
}
