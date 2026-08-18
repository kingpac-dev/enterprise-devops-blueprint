using Microsoft.Extensions.Diagnostics.HealthChecks;
using Orders.Api;
using Xunit;

namespace Orders.Api.Tests;

public sealed class ApiOptionsTests
{
    [Fact]
    public void Validate_accepts_a_complete_configuration()
    {
        new ApiOptions
        {
            DatabaseConnectionString = "Server=db;Database=orders",
            JwtSigningKey = "placeholder-not-a-real-key",
        }.Validate();
    }

    [Fact]
    public void Validate_rejects_a_missing_connection_string()
    {
        var options = new ApiOptions { JwtSigningKey = "placeholder" };

        var ex = Assert.Throws<InvalidOperationException>(options.Validate);
        Assert.Contains(nameof(ApiOptions.DatabaseConnectionString), ex.Message);
    }

    [Fact]
    public void Validate_names_every_missing_setting_at_once()
    {
        // One start, one complete answer. Reporting them one at a time means
        // a deployment fails, is fixed, and fails again on the next value.
        var ex = Assert.Throws<InvalidOperationException>(new ApiOptions().Validate);

        Assert.Contains(nameof(ApiOptions.DatabaseConnectionString), ex.Message);
        Assert.Contains(nameof(ApiOptions.JwtSigningKey), ex.Message);
    }

    [Fact]
    public void Validate_message_contains_no_configuration_VALUES()
    {
        // The message reaches the container log, which is collected centrally
        // and retained. It names settings; it must never echo their values.
        const string secret = "super-secret-value";
        var options = new ApiOptions { DatabaseConnectionString = secret };

        var ex = Assert.Throws<InvalidOperationException>(options.Validate);

        Assert.DoesNotContain(secret, ex.Message);
    }

    [Fact]
    public void Diagnostic_endpoints_default_to_disabled()
    {
        // A default must be SAFE when nothing overrides it.
        Assert.False(new ApiOptions().EnableDiagnosticEndpoints);
    }
}

public sealed class HealthCheckTests
{
    [Fact]
    public async Task Liveness_stays_healthy_when_dependencies_are_down()
    {
        // THE point of separating liveness from readiness.
        //
        // If liveness checked the database, a slow database would fail every
        // instance's probe and restart every container — repeatedly, adding
        // connection churn to a dependency already under strain.
        var live = new ProcessHealthCheck();

        var result = await live.CheckHealthAsync(new HealthCheckContext());

        Assert.Equal(HealthStatus.Healthy, result.Status);
    }

    [Fact]
    public async Task Readiness_reports_unhealthy_when_a_dependency_is_down()
    {
        var ready = new DependencyHealthCheck(_ => Task.FromResult(false));

        var result = await ready.CheckHealthAsync(new HealthCheckContext());

        Assert.Equal(HealthStatus.Unhealthy, result.Status);
    }

    [Fact]
    public async Task Readiness_reports_unhealthy_when_the_probe_throws()
    {
        var ready = new DependencyHealthCheck(
            _ => throw new InvalidOperationException("Server=db.internal;Password=hunter2"));

        var result = await ready.CheckHealthAsync(new HealthCheckContext());

        Assert.Equal(HealthStatus.Unhealthy, result.Status);
    }

    [Fact]
    public async Task Readiness_description_leaks_no_dependency_detail()
    {
        // The exception carries a connection string, as real ones routinely
        // do. It must not reach the health response, which is frequently the
        // least protected route in the service.
        var ready = new DependencyHealthCheck(
            _ => throw new InvalidOperationException("Server=db.internal;Password=hunter2"));

        var result = await ready.CheckHealthAsync(new HealthCheckContext());

        Assert.NotNull(result.Description);
        Assert.DoesNotContain("db.internal", result.Description);
        Assert.DoesNotContain("hunter2", result.Description);
        Assert.DoesNotContain("Password", result.Description);
    }
}
