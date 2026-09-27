# Benchmark

Idle footprint and CPU of notch apps on a 14-inch MacBook Pro (M3 Pro, macOS 26.5), measured with `footprint` and
the process CPU time over 60 seconds with no interaction, 20 seconds after launch.

| App | Version | Memory at rest | Peak | CPU at rest |
|---|---|---|---|---|
| Islet | 0.1.0 (shell only) | 9.4 MB | 9.9 MB | 0 % |

Measured 2026-09-27. To reproduce: `scripts/bench.sh <pid>`.
