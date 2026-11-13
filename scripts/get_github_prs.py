#!/usr/bin/env python3
import os
import sys
import json
import time
import subprocess
from datetime import datetime, timezone

CACHE_FILE = "/tmp/github_prs_cache.json"
CACHE_TTL = 90  # seconds

def format_relative_time(iso_str):
    if not iso_str:
        return ""
    try:
        dt = datetime.fromisoformat(iso_str.replace("Z", "+00:00"))
        now = datetime.now(timezone.utc)
        diff = now - dt
        seconds = max(0, int(diff.total_seconds()))
        if seconds < 60:
            return "just now"
        minutes = seconds // 60
        if minutes < 60:
            return f"{minutes}m ago"
        hours = minutes // 60
        if hours < 24:
            return f"{hours}h ago"
        days = hours // 24
        if days < 30:
            return f"{days}d ago"
        months = days // 30
        if months < 12:
            return f"{months}mo ago"
        years = days // 365
        return f"{years}y ago"
    except Exception:
        return iso_str

def fetch_prs_graphql():
    query = """
query {
  viewer {
    pullRequests(first: 100, states: OPEN, orderBy: {field: UPDATED_AT, direction: DESC}) {
      totalCount
      nodes {
        number
        title
        url
        updatedAt
        isDraft
        comments {
          totalCount
        }
        repository {
          name
          nameWithOwner
        }
        commits(last: 1) {
          nodes {
            commit {
              statusCheckRollup {
                state
              }
            }
          }
        }
      }
    }
  }
}
"""
    cmd = ["gh", "api", "graphql", "-f", f"query={query}"]
    res = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
    if res.returncode != 0:
        raise RuntimeError(res.stderr.strip() or f"gh exited with {res.returncode}")

    data = json.loads(res.stdout)
    pr_container = data.get("data", {}).get("viewer", {}).get("pullRequests", {})
    total_count = pr_container.get("totalCount", 0)
    nodes = pr_container.get("nodes", [])
    prs = []
    for item in nodes:
        repo_data = item.get("repository") or {}
        repo_name = repo_data.get("name", "repo")
        full_repo = repo_data.get("nameWithOwner", repo_name)

        ci_status = "none"
        commits_nodes = (item.get("commits") or {}).get("nodes") or []
        if commits_nodes:
            last_commit = commits_nodes[0].get("commit") or {}
            rollup = last_commit.get("statusCheckRollup") or {}
            raw_state = rollup.get("state")
            if raw_state == "SUCCESS":
                ci_status = "success"
            elif raw_state in ("PENDING", "EXPECTED"):
                ci_status = "pending"
            elif raw_state in ("FAILURE", "ERROR"):
                ci_status = "failure"

        comments_count = (item.get("comments") or {}).get("totalCount", 0)

        prs.append({
            "number": item.get("number", 0),
            "title": item.get("title", ""),
            "repo": repo_name,
            "full_repo": full_repo,
            "url": item.get("url", ""),
            "is_draft": bool(item.get("isDraft", False)),
            "comments": comments_count,
            "ci_status": ci_status,
            "updated_at": item.get("updatedAt", ""),
            "updated_ago": format_relative_time(item.get("updatedAt", ""))
        })
    return total_count, prs

def fetch_prs_search_fallback():
    cmd = [
        "gh", "search", "prs",
        "--state=open",
        "--author=@me",
        "--limit=100",
        "--json", "number,title,repository,url,updatedAt,isDraft,commentsCount,labels"
    ]
    res = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
    if res.returncode != 0:
        raise RuntimeError(res.stderr.strip() or f"gh exited with {res.returncode}")

    raw_items = json.loads(res.stdout)
    prs = []
    for item in raw_items:
        repo_data = item.get("repository", {})
        repo_name = repo_data.get("name", "repo")
        full_repo = repo_data.get("nameWithOwner", repo_name)

        prs.append({
            "number": item.get("number", 0),
            "title": item.get("title", ""),
            "repo": repo_name,
            "full_repo": full_repo,
            "url": item.get("url", ""),
            "is_draft": bool(item.get("isDraft", False)),
            "comments": item.get("commentsCount", 0),
            "ci_status": "none",
            "updated_at": item.get("updatedAt", ""),
            "updated_ago": format_relative_time(item.get("updatedAt", ""))
        })
    return len(prs), prs

def fetch_prs():
    try:
        total_count, prs = fetch_prs_graphql()
    except Exception:
        total_count, prs = fetch_prs_search_fallback()

    return {
        "status": "ok",
        "count": total_count,
        "prs": prs,
        "updated_at_epoch": time.time(),
        "last_updated": datetime.now().strftime("%I:%M %p")
    }

def main():
    force = "--force" in sys.argv
    now = time.time()
    cached = None

    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r") as f:
                cached = json.load(f)
        except Exception:
            cached = None

    if not force and cached:
        cached_epoch = cached.get("updated_at_epoch", 0)
        if now - cached_epoch < CACHE_TTL:
            print(json.dumps(cached))
            return

    try:
        data = fetch_prs()
        try:
            with open(CACHE_FILE, "w") as f:
                json.dump(data, f)
        except Exception:
            pass
        print(json.dumps(data))
    except Exception as e:
        if cached:
            cached["stale"] = True
            print(json.dumps(cached))
        else:
            print(json.dumps({
                "status": "error",
                "count": 0,
                "prs": [],
                "error": str(e),
                "last_updated": "Error"
            }))

if __name__ == "__main__":
    main()
