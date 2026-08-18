using Orders.Worker;
using Xunit;

namespace Orders.Worker.Tests;

/// <summary>
/// Tests the failure paths, not the happy path.
///
/// Failure paths are the least-tested code and the most consequential here:
/// each of these represents a configuration that would start successfully
/// and misbehave later.
/// </summary>
public sealed class WorkerOptionsTests
{
    private static WorkerOptions Valid() => new()
    {
        LivenessFile = "/var/run/worker/alive",
        PollInterval = TimeSpan.FromSeconds(5),
        MaxItemDuration = TimeSpan.FromSeconds(10),
        ShutdownTimeout = TimeSpan.FromSeconds(30),
    };

    [Fact]
    public void Validate_accepts_a_correct_configuration()
    {
        Valid().Validate();
    }

    [Fact]
    public void Validate_rejects_a_missing_liveness_file()
    {
        var options = new WorkerOptions
        {
            LivenessFile = string.Empty,
            ShutdownTimeout = TimeSpan.FromSeconds(30),
            MaxItemDuration = TimeSpan.FromSeconds(10),
        };

        var ex = Assert.Throws<InvalidOperationException>(options.Validate);
        Assert.Contains("LivenessFile", ex.Message);
    }

    [Fact]
    public void Validate_rejects_a_shutdown_timeout_shorter_than_one_item()
    {
        // The failure this prevents: a deployment terminates the worker
        // mid-item, leaving a partial write or an unacknowledged message.
        var options = new WorkerOptions
        {
            LivenessFile = "/var/run/worker/alive",
            MaxItemDuration = TimeSpan.FromSeconds(30),
            ShutdownTimeout = TimeSpan.FromSeconds(10),
        };

        var ex = Assert.Throws<InvalidOperationException>(options.Validate);
        Assert.Contains("ShutdownTimeout", ex.Message);
    }

    [Fact]
    public void Validate_rejects_a_non_positive_poll_interval()
    {
        var options = new WorkerOptions
        {
            LivenessFile = "/var/run/worker/alive",
            PollInterval = TimeSpan.Zero,
            MaxItemDuration = TimeSpan.FromSeconds(10),
            ShutdownTimeout = TimeSpan.FromSeconds(30),
        };

        Assert.Throws<InvalidOperationException>(options.Validate);
    }
}
