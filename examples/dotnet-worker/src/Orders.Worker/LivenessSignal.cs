namespace Orders.Worker;

/// <summary>
/// Signals liveness by touching a file after each successful cycle.
///
/// WHY A FILE RATHER THAN AN HTTP ENDPOINT
///
/// A worker has no HTTP surface. Adding a listener purely to answer a health
/// check introduces attack surface to satisfy a convention.
///
/// More importantly, this detects the failure that matters for a worker:
/// PROCESSING HAS STOPPED while the process is still running. A worker that
/// starts, fails to connect to its queue, and retries silently is a running
/// process — so process liveness alone reports success while nothing is
/// being done.
///
/// The container health check reads the file's age. See
/// templates/docker/Dockerfile.dotnet-worker
/// </summary>
public interface ILivenessSignal
{
    /// <summary>Records that a cycle completed successfully.</summary>
    void RecordSuccess();
}

public sealed class FileLivenessSignal : ILivenessSignal
{
    private readonly string _path;
    private readonly TimeProvider _timeProvider;

    public FileLivenessSignal(string path, TimeProvider timeProvider)
    {
        _path = path;
        _timeProvider = timeProvider;

        var directory = Path.GetDirectoryName(_path);
        if (!string.IsNullOrEmpty(directory))
        {
            Directory.CreateDirectory(directory);
        }
    }

    public void RecordSuccess()
    {
        // Written, then stamped. The health check reads the modification
        // time, so the content is irrelevant — it exists to make the file
        // inspectable by a human during troubleshooting.
        var now = _timeProvider.GetUtcNow();
        File.WriteAllText(_path, now.ToString("O"));
        File.SetLastWriteTimeUtc(_path, now.UtcDateTime);
    }
}
