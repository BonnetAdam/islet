#!/bin/bash
# scripts/bench.sh <pid> [seconds]: memory footprint and average CPU of a process over a quiet period.
set -euo pipefail
PID="$1"; SECONDS_IDLE="${2:-60}"
cpu() { ps -o time= -p "$PID" | awk -F'[:.]' '{ if (NF==3) print $1*60+$2+$3/100; else print $1*3600+$2*60+$3+$4/100 }'; }
footprint_of() { footprint -p "$PID" 2>/dev/null | grep -m1 Footprint | sed -E 's/.*Footprint: //; s/ \(.*//'; }
before=$(cpu); sleep "$SECONDS_IDLE"; after=$(cpu)
echo "footprint: $(footprint_of)"
footprint -p "$PID" 2>/dev/null | grep -m1 peak | awk '{print "peak: " $2 " " $3}'
echo "cpu: $(echo "scale=2; ($after-$before)*100/$SECONDS_IDLE" | bc) %"
