namespace Orders.Api;

/// <summary>
/// Configuration supplied at run time. Nothing environment-specific is
/// compiled in, so the same image is promoted to DEV, UAT, and PROD.
/// </summary>
public sealed class ApiOptions
{
    public const string SectionName = "Api";

    /// <summary>Required. No default — see Validate().</summary>
    public string DatabaseConnectionString { get; init; } = string.Empty;

    /// <summary>Required. No default.</summary>
    public string JwtSigningKey { get; init; } = string.Empty;

    /// <summary>
    /// Optional, with a SAFE default. Disabled unless explicitly enabled.
    /// </summary>
    public bool EnableDiagnosticEndpoints { get; init; }

    /// <summary>
    /// Fails fast on missing required configuration.
    ///
    /// The failure mode of a missing override must be "does not start", not
    /// "starts and connects to production". A default that points at a real
    /// system is a defect, not a convenience.
    /// </summary>
    public void Validate()
    {
        var missing = new List<string>();

        if (string.IsNullOrWhiteSpace(DatabaseConnectionString))
        {
            missing.Add($"{SectionName}:{nameof(DatabaseConnectionString)}");
        }

        if (string.IsNullOrWhiteSpace(JwtSigningKey))
        {
            missing.Add($"{SectionName}:{nameof(JwtSigningKey)}");
        }

        if (missing.Count > 0)
        {
            // Names the missing settings; never their values, and never the
            // values of anything else. This message reaches the container log.
            throw new InvalidOperationException(
                "Required configuration is missing: " + string.Join(", ", missing));
        }
    }
}
