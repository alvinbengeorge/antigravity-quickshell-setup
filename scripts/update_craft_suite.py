#!/usr/bin/env python3
"""
Craft Suite Auto-Updater (Wordcraft, Deckcraft, Gridcraft)
Fetches latest release RPMs from GitHub releases (storytold/*)
and upgrades packages cleanly using dnf.
"""

import sys
import json
import urllib.request
import subprocess
import shutil

APPS = ["wordcraft", "deckcraft", "gridcraft"]

def get_installed_version(app_name):
    try:
        output = subprocess.check_output(
            ["rpm", "-q", "--queryformat", "%{VERSION}", app_name],
            stderr=subprocess.DEVNULL
        ).decode().strip()
        return output
    except Exception:
        return None

def get_latest_release(app_name):
    url = f"https://api.github.com/repos/storytold/{app_name}/releases/latest"
    req = urllib.request.Request(url, headers={"User-Agent": "CraftSuite-Updater"})
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode())
        
        tag = data.get("tag_name", "").lstrip("v")
        assets = data.get("assets", [])
        rpm_url = None
        for a in assets:
            name = a.get("name", "")
            if name.endswith(".rpm") and ("x86_64" in name or "linux-x86_64" in name) and not name.endswith(".asc"):
                rpm_url = a.get("browser_download_url")
                break
        return tag, rpm_url
    except Exception as e:
        print(f"Error fetching release for {app_name}: {e}")
        return None, None

def main():
    check_only = "--check" in sys.argv
    print("✦ Checking Storytold Craft Suite updates...\n")

    updates_to_install = []
    
    for app in APPS:
        curr = get_installed_version(app)
        latest, rpm_url = get_latest_release(app)
        
        if not latest or not rpm_url:
            print(f"  [?] {app}: installed {curr or 'none'}, failed to fetch latest.")
            continue
            
        if curr != latest:
            print(f"  ⬆ {app}: {curr or 'none'} ➔ {latest} (Update available)")
            updates_to_install.append((app, latest, rpm_url))
        else:
            print(f"  ✓ {app}: {curr} (Up to date)")

    print()
    if not updates_to_install:
        print("🎉 All Craft Suite apps are up to date!")
        return 0

    if check_only:
        print(f"{len(updates_to_install)} updates available.")
        return 0

    print(f"Ready to upgrade {len(updates_to_install)} apps.")
    rpm_urls = [u[2] for u in updates_to_install]

    auth_cmd = "sudo" if shutil.which("sudo") else "pkexec"
    cmd = [auth_cmd, "dnf", "upgrade", "-y"] + rpm_urls
    
    print(f"Executing: {' '.join(cmd)}\n")
    try:
        res = subprocess.run(cmd)
        if res.returncode == 0:
            print("\n✨ Craft Suite successfully upgraded to latest versions!")
            try:
                subprocess.run([
                    "notify-send",
                    "Craft Suite Updated",
                    "Wordcraft, Deckcraft, and Gridcraft are now running the latest releases.",
                    "-a", "Antigravity Shell"
                ], stderr=subprocess.DEVNULL)
            except Exception:
                pass
        return res.returncode
    except Exception as err:
        print(f"Failed to execute dnf: {err}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
