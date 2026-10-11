#!/usr/bin/env python3
import subprocess
import json
import time
import os

CACHE_FILE = '/tmp/agy_quota_cache.json'
LOCK_FILE = '/tmp/agy_quota_cache.lock'

def update_cache():
    # Avoid concurrent fetches
    if os.path.exists(LOCK_FILE):
        try:
            mtime = os.path.getmtime(LOCK_FILE)
            if time.time() - mtime < 15:
                return  # already running
        except Exception:
            pass

    try:
        with open(LOCK_FILE, 'w') as f:
            f.write(str(os.getpid()))

        agy_bin = os.path.expanduser('~/.local/bin/agy')
        if not os.path.exists(agy_bin):
            import shutil
            agy_bin = shutil.which('agy') or 'agy'

        env = os.environ.copy()
        env['PATH'] = f"{os.path.expanduser('~/.local/bin')}:{env.get('PATH', '')}"

        res = subprocess.run(
            [agy_bin, '--print', '/quota', '--output-format', 'json'],
            capture_output=True,
            text=True,
            timeout=15,
            env=env
        )

        if res.returncode == 0 and res.stdout.strip():
            data = json.loads(res.stdout)
            cmd_data = data.get('command', {}).get('data', {})
            groups = cmd_data.get('groups', [])
            parsed = {}
            for g in groups:
                gname = g.get('name', '')
                for b in g.get('buckets', []):
                    w = b.get('window', '')
                    rem = round(b.get('remaining_fraction', 0.0) * 100.0)
                    key = f"{gname}_{w}"
                    parsed[key] = {
                        'group': gname,
                        'window': w,
                        'name': b.get('name', ''),
                        'remaining': rem,
                        'reset_time': b.get('reset_time', ''),
                        'description': b.get('description', '')
                    }

            with open(CACHE_FILE, 'w') as f:
                json.dump({
                    'updated_at': time.time(),
                    'quotas': parsed
                }, f)
    except Exception as e:
        pass
    finally:
        if os.path.exists(LOCK_FILE):
            try:
                os.remove(LOCK_FILE)
            except Exception:
                pass

if __name__ == '__main__':
    update_cache()
