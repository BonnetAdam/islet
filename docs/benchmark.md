# Benchmark

Idle memory footprint and CPU of Islet on a 14-inch MacBook Pro (M3 Pro, macOS 26.5), measured with `footprint` and
the process's CPU time over 60 seconds without interaction, 20 seconds after launch. Helper processes count.

| State | Islet | Media helper | CPU |
|---|---|---|---|
| Closed, nothing playing, every feature on | 12 MB | 4.5 MB | 0.03 % |
| First version, island only | 9.4 MB | | 0 % |
| Open, music playing | 16 MB | 4.5 MB | 0.1 % |

Other notch apps measured the same way, the same night, used 49 to 106 MB at rest (peaks up to 221 MB) and from 0.01 %
to 6.8 % of the processor.

To reproduce: `scripts/bench.sh <pid> [seconds]`.
