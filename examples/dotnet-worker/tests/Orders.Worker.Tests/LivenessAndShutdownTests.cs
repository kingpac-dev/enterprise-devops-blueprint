using Microsoft.Extensions.Logging.Abstractions;
using Orders.Worker;
using Xunit;

namespace Orders.Worker.Tests;

public sealed class FileLivenessSignalTests : IDisposable
{
    private readonly string _dir = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());

    [Fact]
    public void RecordSuccess_creates_the_file_and_its_directory()
    {
        var path = Path.Combine(_dir, "nested", "alive");
        var signal = new FileLivenessSignal(path, TimeProvider.System);

        signal.RecordSuccess();

        Assert.True(File.Exists(path));
    }

    [Fact]
    public void RecordSuccess_advances_the_modification_time()
    {
        // The container health check reads the file's AGE. If the timestamp
        // does not advance, a working worker is reported as stalled.
        var path = Path.Combine(_dir, "alive");
        var clock = new FakeTimeProvider(DateTimeOffset.UtcNow);
        var signal = new FileLivenessSignal(path, clock);

        signal.RecordSuccess();
        var first = File.GetLastWriteTimeUtc(path);

        clock.Advance(TimeSpan.FromMinutes(5));
        signal.RecordSuccess();
        var second = File.GetLastWriteTimeUtc(path);

        Assert.True(second > first, "The liveness timestamp must advance on each successful cycle.");
    }

    public void Dispose()
    {
        if (Directory.Exists(_dir))
        {
            Directory.Delete(_dir, recursive: true);
        }
    }
}

public sealed class QueueProcessorTests
{
    [Fact]
    public async Task Liveness_is_NOT_recorded_when_a_cycle_fails()
    {
        // The failure this guards against: a worker looping and failing while
        // reporting itself alive. Process liveness alone would report success.
        var liveness = new RecordingLivenessSignal();
        var source = new ThrowingItemSource();
        var options = new WorkerOptions
        {
            LivenessFile = "unused",
            PollInterval = TimeSpan.FromMilliseconds(10),
            MaxItemDuration = TimeSpan.FromSeconds(1),
            ShutdownTimeout = TimeSpan.FromSeconds(5),
        };

        var processor = new QueueProcessor(
            options, liveness, source, NullLogger<QueueProcessor>.Instance);

        using var cts = new CancellationTokenSource(TimeSpan.FromMilliseconds(200));
        await processor.StartAsync(cts.Token);
        await Task.Delay(120, CancellationToken.None);
        await processor.StopAsync(CancellationToken.None);

        Assert.True(source.FetchCount > 0, "The processor should have attempted at least one cycle.");
        Assert.Equal(0, liveness.SuccessCount);
    }

    [Fact]
    public async Task Liveness_is_recorded_after_a_successful_cycle()
    {
        var liveness = new RecordingLivenessSignal();
        var source = new EmptyItemSource();
        var options = new WorkerOptions
        {
            LivenessFile = "unused",
            PollInterval = TimeSpan.FromMilliseconds(10),
            MaxItemDuration = TimeSpan.FromSeconds(1),
            ShutdownTimeout = TimeSpan.FromSeconds(5),
        };

        var processor = new QueueProcessor(
            options, liveness, source, NullLogger<QueueProcessor>.Instance);

        using var cts = new CancellationTokenSource(TimeSpan.FromMilliseconds(200));
        await processor.StartAsync(cts.Token);
        await Task.Delay(120, CancellationToken.None);
        await processor.StopAsync(CancellationToken.None);

        Assert.True(liveness.SuccessCount > 0);
    }

    [Fact]
    public async Task An_item_that_has_started_is_finished_even_during_shutdown()
    {
        // Abandoning an item mid-way can leave a partial write or an
        // unacknowledged message. Shutdown is checked BETWEEN items.
        var liveness = new RecordingLivenessSignal();
        var source = new SlowItemSource(itemCount: 3, perItem: TimeSpan.FromMilliseconds(60));
        var options = new WorkerOptions
        {
            LivenessFile = "unused",
            PollInterval = TimeSpan.FromMilliseconds(10),
            MaxItemDuration = TimeSpan.FromSeconds(1),
            ShutdownTimeout = TimeSpan.FromSeconds(5),
        };

        var processor = new QueueProcessor(
            options, liveness, source, NullLogger<QueueProcessor>.Instance);

        await processor.StartAsync(CancellationToken.None);
        await Task.Delay(90, CancellationToken.None);   // mid-batch
        await processor.StopAsync(CancellationToken.None);

        Assert.Equal(0, source.AbandonedCount);
    }

    private sealed class RecordingLivenessSignal : ILivenessSignal
    {
        public int SuccessCount { get; private set; }

        public void RecordSuccess() => SuccessCount++;
    }

    private sealed class EmptyItemSource : IItemSource
    {
        public Task<IReadOnlyList<string>> FetchAsync(CancellationToken cancellationToken)
            => Task.FromResult<IReadOnlyList<string>>(Array.Empty<string>());

        public Task ProcessAsync(string item, CancellationToken cancellationToken)
            => Task.CompletedTask;
    }

    private sealed class ThrowingItemSource : IItemSource
    {
        public int FetchCount;

        public Task<IReadOnlyList<string>> FetchAsync(CancellationToken cancellationToken)
        {
            Interlocked.Increment(ref FetchCount);
            throw new InvalidOperationException("queue unreachable");
        }

        public Task ProcessAsync(string item, CancellationToken cancellationToken)
            => Task.CompletedTask;
    }

    private sealed class SlowItemSource : IItemSource
    {
        private readonly int _itemCount;
        private readonly TimeSpan _perItem;
        private int _started;
        private int _completed;

        public SlowItemSource(int itemCount, TimeSpan perItem)
        {
            _itemCount = itemCount;
            _perItem = perItem;
        }

        public int AbandonedCount => Volatile.Read(ref _started) - Volatile.Read(ref _completed);

        public Task<IReadOnlyList<string>> FetchAsync(CancellationToken cancellationToken)
            => Task.FromResult<IReadOnlyList<string>>(
                Enumerable.Range(0, _itemCount).Select(i => $"item-{i}").ToArray());

        public async Task ProcessAsync(string item, CancellationToken cancellationToken)
        {
            Interlocked.Increment(ref _started);
            await Task.Delay(_perItem, cancellationToken).ConfigureAwait(false);
            Interlocked.Increment(ref _completed);
        }
    }
}

/// <summary>Minimal controllable clock, so the test does not depend on wall time.</summary>
internal sealed class FakeTimeProvider : TimeProvider
{
    private DateTimeOffset _now;

    public FakeTimeProvider(DateTimeOffset start) => _now = start;

    public override DateTimeOffset GetUtcNow() => _now;

    public void Advance(TimeSpan by) => _now = _now.Add(by);
}
