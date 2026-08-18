namespace Orders.Worker;

/// <summary>
/// Configuration for the worker.
///
/// Every value is supplied at run time. Nothing environment-specific is
/// compiled in, so the same image is promoted to DEV, UAT, and PROD.
/// See docs/01-architecture/environment-architecture.md
/// </summary>
public sealed class WorkerOptions
{
    public const string SectionName = "Worker";

    /// <summary>
    /// Path the worker touches after each successful cycle. The container
    /// health check reads its age.
    ///
    /// Required. A worker with no liveness signal cannot be safely deployed
    /// by a pipeline, because the pipeline cannot distinguish "started" from
    /// "working".
    /// </summary>
    public string LivenessFile { get; init; } = string.Empty;

    /// <summary>Interval between processing cycles.</summary>
    public TimeSpan PollInterval { get; init; } = TimeSpan.FromSeconds(5);

    /// <summary>
    /// How long a single item may take. Used only to make the relationship
    /// with the shutdown timeout explicit and checkable — see Validate().
    /// </summary>
    public TimeSpan MaxItemDuration { get; init; } = TimeSpan.FromSeconds(10);

    /// <summary>
    /// Time the host allows for graceful shutdown.
    ///
    /// MUST be shorter than the container stop grace period, or the process
    /// is killed while it still believes it has time to finish. See
    /// docs/06-container/docker-standard.md
    /// </summary>
    public TimeSpan ShutdownTimeout { get; init; } = TimeSpan.FromSeconds(30);

    /// <summary>
    /// Fails fast on a configuration that cannot work.
    ///
    /// Starting with a wrong value is worse than not starting: the failure
    /// surfaces later as incorrect behaviour rather than as a failed
    /// deployment.
    /// </summary>
    public void Validate()
    {
        if (string.IsNullOrWhiteSpace(LivenessFile))
        {
            throw new InvalidOperationException(
                $"{SectionName}:{nameof(LivenessFile)} is required. Without it the container " +
                "health check cannot distinguish a working worker from a stalled one.");
        }

        if (PollInterval <= TimeSpan.Zero)
        {
            throw new InvalidOperationException(
                $"{SectionName}:{nameof(PollInterval)} must be positive.");
        }

        // A shutdown timeout shorter than one item's processing time means a
        // deployment can kill the worker mid-transaction, which is the
        // difference between a clean deployment and a data-integrity
        // incident.
        if (ShutdownTimeout <= MaxItemDuration)
        {
            throw new InvalidOperationException(
                $"{SectionName}:{nameof(ShutdownTimeout)} ({ShutdownTimeout}) must exceed " +
                $"{nameof(MaxItemDuration)} ({MaxItemDuration}), or a deployment can terminate " +
                "the worker mid-item.");
        }
    }
}
