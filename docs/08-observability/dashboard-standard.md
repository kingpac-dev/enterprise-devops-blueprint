# Dashboard Standard

## Purpose

Defines which dashboards exist, how panels are chosen and laid out, and the readability and colour rules that make a dashboard usable during an incident.

## Scope

Grafana dashboards over Prometheus and Loki. Alert rules are in [alerting-standard.md](alerting-standard.md); metric conventions are in [monitoring-standard.md](monitoring-standard.md).

## Audience

Developers and platform engineers who build dashboards, and reviewers of them.

## Status

**Draft for review.** Not implemented. The colour palette has not been selected or validated.

---

## 1. What a Dashboard Is For

A dashboard answers *what is happening* and *why*. An alert says *act now*. They are different jobs and the distinction should be maintained deliberately:

| Need | Mechanism |
| --- | --- |
| Something requires action | Alert |
| Is the system healthy right now? | Dashboard |
| Why is it unhealthy? | Dashboard, then logs |
| Did the deployment change anything? | Dashboard with deployment annotations |
| Long-term trend and capacity | Dashboard |

A dashboard nobody opens during an incident has failed, whatever it contains. The design test throughout this document is: can someone who did not build it, under time pressure, find the answer?

---

## 2. Required Dashboards

| Dashboard | Scope | Answers |
| --- | --- | --- |
| Service overview | One service, one environment | Is this service healthy? |
| Platform overview | Jenkins, Harbor, SonarQube, Loki, Prometheus | Is the toolchain healthy? |
| Host overview | Runtime hosts | CPU, memory, disk, container counts |
| Deployment view | Recent releases | What changed, and when |

`TBD` — whether per-team or per-environment aggregate dashboards are also required. More dashboards is not better; each one is a maintenance obligation, and an out-of-date dashboard is worse than none because it is believed.

---

## 3. Layout

### Reading order

Top-left is read first. Put the answer to "is it broken?" there, and detail below.

```text
┌──────────────────────────────────────────────────────────┐
│ Filter row: environment, service, time range             │
├──────────────────────────────────────────────────────────┤
│ [ Availability ] [ Error rate ] [ p95 latency ] [ Restarts ]   ← stat tiles
├──────────────────────────────────────────────────────────┤
│ Request rate over time        │ Error rate over time     │   ← trend
├───────────────────────────────┼──────────────────────────┤
│ Latency percentiles           │ Errors by type           │
├──────────────────────────────────────────────────────────┤
│ CPU / memory / restarts                                  │   ← saturation
├──────────────────────────────────────────────────────────┤
│ Recent error logs                                        │   ← detail
└──────────────────────────────────────────────────────────┘
```

The order is: **state, then trend, then saturation, then detail.** Someone opening this during an incident gets the yes/no answer without scrolling.

### Filters

One filter row at the top, scoping every panel below it. Never per-panel filters, and never a filter inside a panel — a dashboard where two panels show different time ranges or different environments will be misread, and it will be misread at the worst time.

Environment must be a filter, and it must be visibly displayed. A dashboard that silently shows DEV while the reader believes it shows PROD is an incident-prolonging device.

### Size

One screen for the top section. If the reader must scroll to learn whether the service is up, the layout is wrong.

`TBD` — a maximum panel count per dashboard. Beyond roughly 20 panels, dashboards stop being read and start being scrolled past.

---

## 4. Panel Selection

Pick the panel by the job the data does, before choosing anything about its appearance.

| The data is | Use | Not |
| --- | --- | --- |
| One current value, possibly with a trend | **Stat tile** (value, delta, sparkline) | A single-series bar or gauge |
| A handful of headline numbers | **Row of stat tiles** | A grouped bar chart |
| One ratio against a limit — disk used, quota | **Bar gauge or meter** | A two-slice pie |
| Change over time | **Time series** | A table of timestamps |
| Distinct series compared over time | **Time series**, multi-line | Stacked area, unless part-to-whole is the point |
| Part-to-whole over time | **Stacked area or stacked bar** | Multi-line |
| A distribution — latency spread | **Heatmap** | Averaged line |
| More than about seven classes that all matter | **Table** | More colours |
| Recent log lines | **Logs panel** | A table |

Two selections in that list are worth stating as rules.

**A single number is a stat tile, not a chart.** A one-bar bar chart and a two-slice pie both take a panel's worth of space to show a number that would be legible at a glance as text.

**Latency is a distribution, not an average.** An averaged latency line hides the tail, and the tail is what users experience. Show percentiles, or a heatmap.

---

## 5. Never Use a Second Y-Axis

**A panel has one y-axis. Two measures with different scales go in two panels.**

This is the most common and most damaging dashboard mistake. Plotting error count against latency on one panel with two independently scaled axes means the alignment between the two lines is an artifact of how the axes were scaled. The chart appears to show a correlation that is not in the data, and people act on it.

Where two measures genuinely need visual comparison, index both to a common base and plot them on one axis, or place two panels side by side with the same time range.

---

## 6. Colour

### Colour has jobs; each job has one rule

| Job | Rule |
| --- | --- |
| **Identity** — telling series apart | A fixed categorical palette, assigned in fixed order |
| **Magnitude** — heatmaps, more-is-more | One hue, light to dark |
| **Polarity** — above or below a baseline | Two opposed hues with a **neutral grey** midpoint |
| **Status** — good, warning, serious, critical | The reserved status palette only |

Never a rainbow ramp for magnitude. Grafana ships spectral schemes for heatmaps and they are the wrong default: a rainbow has no perceptual order, so the reader cannot tell which end is "more" without consulting the legend on every glance.

Never a hue at the midpoint of a diverging scale — the midpoint must read as "nothing". Two cool hues as the two poles fails for the same reason: they do not read as opposite.

### Status colours are reserved

The good / warning / serious / critical colours mean state. They must never be reused as "the colour of the fourth series", and a series colour must never be used to mean status. Once the two overlap, no colour on the dashboard has a reliable meaning.

**Status must never be colour alone.** Grafana threshold colouring is colour-only by default. Pair it with the value, a text label, or an icon — for a colourblind reader, and for anyone reading a screenshot in a monochrome ticket export.

### Series colours must be pinned

Grafana assigns palette colours by series order by default. When a template variable filters the series list, the survivors are repainted — so a reader who learned "orders-api is blue" is now looking at a different service in blue.

Pin colours explicitly per series or per field. **Colour follows the entity, never its position in the list.**

### Series count

| Series | Treatment |
| --- | --- |
| 1–3 | Comfortable; label directly |
| 4 | Direct labels become necessary |
| 5–6 | Soft cap; use a legend |
| 7–8 | Ceiling |
| 9+ | Fold the tail into "Other", or split into repeated panels per series |

Never solve "too many series" by adding more colours. A ninth generated hue is indistinguishable from an existing one for a colourblind reader, and frequently for everyone else.

### Validate the palette; do not eyeball it

Whether two colours are distinguishable under the common forms of colour vision deficiency is a computation, not a judgement. Around 1 in 12 men has some form of CVD, so a palette that "looks fine" to its author is not evidence.

`TBD` — the chosen palette and its validation. Requirements: adjacent pairs separated under simulated deuteranopia and protanopia, sufficient contrast against the dashboard surface, and validation performed against the **dark** surface if dashboards are dark by default, rather than assuming a light-mode palette inverts acceptably.

---

## 7. Marks and Chrome

| Rule | Reason |
| --- | --- |
| Thin lines, hairline grid | Heavy grids compete with the data |
| Solid gridlines, never dashed | Dashing reads as "threshold" or "projection" |
| Grid one shade off the surface | Recessive, present when looked for |
| No value label on every point | Unreadable, and unread |
| Legend present whenever there are two or more series | Identity must not be colour-alone |
| Direct-label selectively | The endpoint, the outlier, the series that matters |
| Threshold lines clearly distinguished from grid | They mean something; the grid does not |
| Y-axis starts at zero for counts and rates | A truncated axis exaggerates variation |

The zero-baseline rule has one legitimate exception: a metric that varies within a narrow band far from zero, where the variation is the subject. Where the axis is truncated, say so on the panel.

---

## 8. Time Range and Refresh

| Setting | Guidance |
| --- | --- |
| Default range | Wide enough to show normal behaviour for comparison. `TBD` — 6 or 24 hours as a starting default |
| Refresh interval | No faster than the scrape interval. Faster refresh redraws identical data |
| Relative time | Prefer relative ranges so the dashboard is useful when opened cold |

A refresh interval faster than the scrape interval creates load and displays nothing new. `TBD` — the standard refresh, once the scrape interval is decided in [monitoring-standard.md](monitoring-standard.md).

---

## 9. Deployment Annotations

Every dashboard showing production metrics must display deployment markers.

The most frequently asked incident question is *did this start when we deployed?* An annotation answers it in one glance. Without it, the answer requires someone to recall the release time and estimate against a graph, under pressure, which is both slow and unreliable.

Annotations carry service, version, and environment. The marker source is `TBD` — see [observability-standard.md](observability-standard.md#6-deployment-markers).

---

## 10. Dashboards as Code

Dashboards are stored as JSON in version control and provisioned, not hand-edited in the UI.

The reasons are the same ones that apply to everything else in this blueprint: a hand-edited dashboard cannot be reviewed, cannot be reproduced after a Grafana rebuild, and drifts between environments without anyone noticing. A dashboard that exists only in one Grafana instance is lost when that instance is.

`TBD` — provisioning mechanism, and where dashboard JSON lives. Templates go in [templates/monitoring/](../../templates/monitoring/).

Consequence: dashboard changes go through pull request, like any other change. That is deliberate friction, and it is the reason dashboards stay reviewable.

---

## 11. Accessibility

| Requirement | Reason |
| --- | --- |
| Identity never colour-alone | Legends and direct labels carry it too |
| Status never colour-alone | Value, label, or icon accompanies the colour |
| Palette validated for CVD | Roughly 1 in 12 men is affected |
| Values readable without hover | Tooltips enhance; they must not be the only path to a number |
| Panel titles state units | "Latency" is ambiguous; "Latency (seconds, p95)" is not |

The tooltip rule matters operationally as well as for accessibility. Dashboards are screenshotted into tickets and chat constantly, and a screenshot has no hover.

---

## 12. Review

A dashboard is maintained or it decays. Metric names change, services are renamed, and panels quietly show nothing.

`TBD` — review frequency. At review:

- Does every panel still return data? An empty panel reads as "zero", which is a dangerous way to be wrong.
- Was any panel used during the last incident? Unused panels are candidates for removal.
- Was any question asked during an incident that the dashboard could not answer? That is a panel worth adding.
- Do the colours still match the standard?

The second and third questions are the useful ones. Incident reviews are the best available source of evidence about which panels earn their place.

---

## 13. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — colour palette selection and CVD validation, against the default surface | Readability for all readers |
| `TBD` — provisioning mechanism and dashboard JSON location | Reproducibility, review |
| `TBD` — default time range and refresh interval | Load, usability |
| `TBD` — deployment annotation source | Incident correlation |
| `TBD` — maximum panel count per dashboard | Usability |
| `TBD` — whether per-team aggregate dashboards exist | Maintenance burden |
| `TBD` — dashboard review frequency and owner | Long-term accuracy |

---

## Security Considerations

Dashboards aggregate operational data and are frequently granted broader access than the systems they describe. Panels showing log content can expose whatever the logging standard failed to keep out — see [logging-standard.md](logging-standard.md#5-what-must-never-be-logged).

Panel titles, service names, and error messages are reconnaissance value. Grafana access should be scoped like access to the underlying data, and public or anonymous dashboard access should not be enabled without a deliberate decision.

Dashboard JSON in version control must contain no credentials. Data source authentication is configured in Grafana, never embedded in a dashboard definition.

## Operational Considerations

The failure mode to design against is a dashboard that is believed and wrong. An empty panel caused by a renamed metric renders as zero, and zero errors reads as healthy. Panels that stop returning data should be detected rather than discovered.

The second failure is dashboard proliferation. Every dashboard is a maintenance obligation, and a set of twenty half-maintained dashboards is less useful than four accurate ones — because nobody knows which to trust.

---

## Related

- [Observability standard](observability-standard.md)
- [Monitoring standard](monitoring-standard.md)
- [Logging standard](logging-standard.md)
- [Alerting standard](alerting-standard.md)
- [Monitoring templates](../../templates/monitoring/)
- [Operations runbooks](../09-operations/)
