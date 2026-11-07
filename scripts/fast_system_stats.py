#!/usr/bin/env python3
"""
Instantaneous procfs System Telemetry & Network Provider
Computes CPU, RAM, Swap percent, and live Upload/Download network speeds directly from kernel procfs without blocking.
"""

import os
import json
import time

CPU_PREV_FILE = '/tmp/qs_cpu_prev.json'
NET_PREV_FILE = '/tmp/qs_net_prev.json'

def format_speed(b_s):
    if b_s < 1024:
        return f"{int(round(b_s))}B"
    elif b_s < 1024 * 1024:
        kb = b_s / 1024.0
        return f"{int(round(kb))}K" if kb >= 100 else f"{kb:.1f}K"
    else:
        mb = b_s / (1024.0 * 1024.0)
        return f"{mb:.1f}M"

def get_stats():
    # 1. CPU via /proc/stat differential
    cpu_pct = 0
    try:
        with open('/proc/stat', 'r') as f:
            fields = [float(x) for x in f.readline().strip().split()[1:]]
        idle = fields[3] + (fields[4] if len(fields) > 4 else 0)
        total = sum(fields)

        if os.path.exists(CPU_PREV_FILE):
            try:
                with open(CPU_PREV_FILE, 'r') as f:
                    prev = json.load(f)
                d_idle = idle - prev.get('idle', 0)
                d_total = total - prev.get('total', 0)
                if d_total > 0:
                    cpu_pct = max(0, min(100, int(round((1.0 - (d_idle / d_total)) * 100))))
            except Exception:
                pass

        with open(CPU_PREV_FILE, 'w') as f:
            json.dump({'idle': idle, 'total': total}, f)
    except Exception:
        pass

    # 2. RAM & Swap via /proc/meminfo
    mem_pct = 0
    swap_pct = 0
    try:
        with open('/proc/meminfo', 'r') as f:
            data = {}
            for line in f:
                if ':' in line:
                    k, v = line.split(':', 1)
                    data[k.strip()] = v.strip()

        m_tot = int(data.get('MemTotal', '0 kB').split()[0])
        m_avail = int(data.get('MemAvailable', '0 kB').split()[0])
        if m_tot > 0:
            mem_pct = max(0, min(100, int(round((m_tot - m_avail) / float(m_tot) * 100))))

        s_tot = int(data.get('SwapTotal', '0 kB').split()[0])
        s_free = int(data.get('SwapFree', '0 kB').split()[0])
        if s_tot > 0:
            swap_pct = max(0, min(100, int(round((s_tot - s_free) / float(s_tot) * 100))))
    except Exception:
        pass

    # 3. Live Network RX & TX via /proc/net/dev differential
    rx_speed = 0.0
    tx_speed = 0.0
    try:
        rx_total = 0
        tx_total = 0
        with open('/proc/net/dev', 'r') as f:
            for line in f.readlines()[2:]:
                parts = line.split(':')
                if len(parts) == 2:
                    iface = parts[0].strip()
                    # Skip loopback and virtual container interfaces
                    if iface == 'lo' or iface.startswith(('docker', 'br-', 'veth')):
                        continue
                    stats = parts[1].split()
                    rx_total += int(stats[0])
                    tx_total += int(stats[8])

        now = time.time()
        if os.path.exists(NET_PREV_FILE):
            try:
                with open(NET_PREV_FILE, 'r') as f:
                    prev_net = json.load(f)
                dt = now - prev_net.get('time', now)
                if dt > 0.2:
                    rx_speed = max(0.0, (rx_total - prev_net.get('rx', rx_total)) / dt)
                    tx_speed = max(0.0, (tx_total - prev_net.get('tx', tx_total)) / dt)
            except Exception:
                pass

        with open(NET_PREV_FILE, 'w') as f:
            json.dump({'rx': rx_total, 'tx': tx_total, 'time': now}, f)
    except Exception:
        pass

    return json.dumps({
        "cpu": cpu_pct,
        "mem": mem_pct,
        "swap": swap_pct,
        "down": format_speed(rx_speed),
        "up": format_speed(tx_speed)
    })

if __name__ == '__main__':
    print(get_stats())
