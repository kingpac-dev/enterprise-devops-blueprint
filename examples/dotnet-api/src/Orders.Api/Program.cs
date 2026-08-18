using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Orders.Api;

var builder = WebApplication.CreateBuilder(args);

// ---------------------------------------------------------------------------
// Configuration — fail fast
// ---------------------------------------------------------------------------
var options = builder.Configuration
    .GetSection(ApiOptions.SectionName)
    .Get<ApiOptions>() ?? new ApiOptions();

options.Validate();
builder.Services.AddSingleton(options);

// ---------------------------------------------------------------------------
// Logging — stdout, structured, UTC
// ---------------------------------------------------------------------------
builder.Logging.ClearProviders();
builder.Logging.AddSimpleConsole(console =>
{
    console.TimestampFormat = "yyyy-MM-ddTHH:mm:ss.fffZ ";
    console.UseUtcTimestamp = true;
});

// ---------------------------------------------------------------------------
// Health checks — liveness and readiness kept SEPARATE
// ---------------------------------------------------------------------------
builder.Services
    .AddHealthChecks()
    // Liveness: this process only. No dependency checks, deliberately.
    .AddCheck<ProcessHealthCheck>("process", tags: new[] { HealthTags.Live })
    // Readiness: may check dependencies. Failure means "stop routing traffic",
    // not "restart me".
    .AddTypeActivatedCheck<DependencyHealthCheck>(
        "database",
        failureStatus: HealthStatus.Unhealthy,
        tags: new[] { HealthTags.Ready },
        args: new object[] { (Func<CancellationToken, Task<bool>>)(_ => Task.FromResult(true)) });

var app = builder.Build();

// ---------------------------------------------------------------------------
// Health endpoints
// ---------------------------------------------------------------------------
// Both return STATUS ONLY. No component list, no versions, no dependency
// names, no exception detail. A health endpoint is frequently the least
// protected route in a service and reachable from further away than intended.
var statusOnly = new HealthCheckOptions
{
    ResponseWriter = static (context, _) =>
    {
        context.Response.ContentType = "text/plain";
        return context.Response.WriteAsync(
            context.Response.StatusCode == StatusCodes.Status200OK ? "ok" : "unhealthy");
    },
};

app.MapHealthChecks("/health/live", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains(HealthTags.Live),
    ResponseWriter = statusOnly.ResponseWriter,
});

app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains(HealthTags.Ready),
    ResponseWriter = statusOnly.ResponseWriter,
});

// ---------------------------------------------------------------------------
// Application
// ---------------------------------------------------------------------------
app.MapGet("/api/orders/{id}", (string id) => Results.Ok(new { id, status = "pending" }));

app.Run();

/// <summary>Exposed so the test project can host this application.</summary>
public partial class Program;
