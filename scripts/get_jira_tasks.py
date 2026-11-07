#!/usr/bin/env python3
import os
import sys
import json
import time
import base64
import urllib.request
import urllib.error
from datetime import datetime, timezone

CACHE_FILE = "/tmp/jira_tasks_cache.json"
AVATAR_CACHE = "/tmp/jira_avatar.png"
CACHE_TTL = 90  # seconds

def find_credentials():
    # 1. Environment variables
    jira_url = os.environ.get("JIRA_URL")
    username = os.environ.get("JIRA_USERNAME")
    token = os.environ.get("ATLASSIAN_TOKEN")
    if jira_url and username and token:
        return jira_url.rstrip("/"), username, token

    # 2. Known .env paths
    env_paths = [
        os.path.expanduser("~/Desktop/projects/jira-mcp/.env"),
        os.path.expanduser("~/.config/jira/.env"),
        os.path.expanduser("~/.jira.env"),
        "/home/alvin/Desktop/projects/jira-mcp/.env"
    ]
    for path in env_paths:
        if os.path.exists(path):
            env_map = {}
            with open(path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith("#") and "=" in line:
                        k, v = line.split("=", 1)
                        env_map[k.strip()] = v.strip().strip('"').strip("'")
            t_url = env_map.get("JIRA_URL")
            t_user = env_map.get("JIRA_USERNAME")
            t_token = env_map.get("ATLASSIAN_TOKEN")
            if t_url and t_user and t_token:
                return t_url.rstrip("/"), t_user, t_token

    # Default fallback
    return (
        "https://askmeidentity.atlassian.net",
        "alvin.george@askmeidentity.com",
        ""
    )

def format_relative_time(iso_str):
    if not iso_str:
        return ""
    try:
        s = iso_str
        if "+" in s and len(s.split("+")[-1]) == 4:
            base, tz = s.rsplit("+", 1)
            s = f"{base}+{tz[:2]}:{tz[2:]}"
        elif "-" in s[10:] and len(s.rsplit("-", 1)[-1]) == 4:
            base, tz = s.rsplit("-", 1)
            s = f"{base}-{tz[:2]}:{tz[2:]}"
        dt = datetime.fromisoformat(s.replace("Z", "+00:00"))
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
        if days == 1:
            return "yesterday"
        if days < 30:
            return f"{days}d ago"
        months = days // 30
        if months < 12:
            return f"{months}mo ago"
        years = days // 365
        return f"{years}y ago"
    except Exception:
        return iso_str[:10]

def fetch_jira_data(jira_url, username, token):
    auth_str = f"{username}:{token}"
    auth_header = "Basic " + base64.b64encode(auth_str.encode("utf-8")).decode("utf-8")

    # 1. Fetch user profile
    req_user = urllib.request.Request(f"{jira_url}/rest/api/3/myself", headers={
        "Authorization": auth_header,
        "Accept": "application/json"
    })
    with urllib.request.urlopen(req_user, timeout=12) as r:
        raw_user = json.loads(r.read().decode("utf-8"))

    avatar_remote = raw_user.get("avatarUrls", {}).get("48x48", "")
    avatar_local = ""
    if avatar_remote:
        try:
            urllib.request.urlretrieve(avatar_remote, AVATAR_CACHE)
            if os.path.exists(AVATAR_CACHE):
                avatar_local = AVATAR_CACHE
        except Exception:
            pass

    user = {
        "displayName": raw_user.get("displayName", username.split("@")[0]),
        "emailAddress": raw_user.get("emailAddress", username),
        "avatarLocal": avatar_local,
        "avatarUrl": avatar_remote,
        "jiraUrl": jira_url,
        "jiraHost": jira_url.replace("https://", "").replace("http://", ""),
        "timeZone": raw_user.get("timeZone", "")
    }

    # 2. Fetch tasks assigned to currentUser()
    payload = json.dumps({
        "jql": "assignee = currentUser() ORDER BY updated DESC",
        "maxResults": 50,
        "fields": ["summary", "status", "priority", "issuetype", "updated", "created", "project"]
    }).encode("utf-8")

    req_issues = urllib.request.Request(f"{jira_url}/rest/api/3/search/jql", data=payload, headers={
        "Authorization": auth_header,
        "Accept": "application/json",
        "Content-Type": "application/json"
    })
    with urllib.request.urlopen(req_issues, timeout=15) as r:
        raw_issues = json.loads(r.read().decode("utf-8")).get("issues", [])

    tasks = []
    to_do_count = 0
    in_progress_count = 0
    done_count = 0

    for item in raw_issues:
        fields = item.get("fields", {})
        status_obj = fields.get("status", {})
        status_cat = status_obj.get("statusCategory", {}).get("name", "To Do")
        status_name = status_obj.get("name", "Unknown")
        
        cat_key = "to_do"
        if status_cat == "In Progress":
            cat_key = "in_progress"
            in_progress_count += 1
        elif status_cat == "Done":
            cat_key = "done"
            done_count += 1
        else:
            to_do_count += 1
            
        priority_name = fields.get("priority", {}).get("name", "Medium")
        p_low = priority_name.lower()
        if "high" in p_low:
            priority_level = "high"
        elif "low" in p_low:
            priority_level = "low"
        else:
            priority_level = "medium"

        issuetype_name = fields.get("issuetype", {}).get("name", "Task")
        proj_name = fields.get("project", {}).get("name", "")
        proj_key = fields.get("project", {}).get("key", "")
        key = item.get("key", "")

        tasks.append({
            "key": key,
            "summary": fields.get("summary", ""),
            "status": status_name,
            "category": cat_key,
            "category_name": status_cat,
            "priority": priority_name,
            "priority_level": priority_level,
            "issuetype": issuetype_name,
            "project": proj_name,
            "project_key": proj_key,
            "updated": fields.get("updated", ""),
            "updated_ago": format_relative_time(fields.get("updated", "")),
            "url": f"{jira_url}/browse/{key}"
        })

    return {
        "status": "ok",
        "user": user,
        "counts": {
            "total": len(tasks),
            "in_progress": in_progress_count,
            "to_do": to_do_count,
            "done": done_count
        },
        "tasks": tasks,
        "last_updated": datetime.now().strftime("%I:%M %p"),
        "updated_at_epoch": time.time()
    }

def main():
    force = "--force" in sys.argv
    now = time.time()
    cached = None

    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r", encoding="utf-8") as f:
                cached = json.load(f)
        except Exception:
            cached = None

    if not force and cached and cached.get("status") == "ok":
        cached_epoch = cached.get("updated_at_epoch", 0)
        if now - cached_epoch < CACHE_TTL:
            print(json.dumps(cached))
            return

    jira_url, username, token = find_credentials()
    if not token:
        if cached:
            print(json.dumps(cached))
            return
        print(json.dumps({
            "status": "error",
            "error": "No ATLASSIAN_TOKEN configured",
            "user": {"displayName": "Anonymous", "emailAddress": "", "avatarLocal": "", "jiraUrl": jira_url},
            "counts": {"total": 0, "in_progress": 0, "to_do": 0, "done": 0},
            "tasks": []
        }))
        return

    try:
        data = fetch_jira_data(jira_url, username, token)
        try:
            with open(CACHE_FILE, "w", encoding="utf-8") as f:
                json.dump(data, f)
        except Exception:
            pass
        print(json.dumps(data))
    except Exception as e:
        if cached:
            print(json.dumps(cached))
            return
        print(json.dumps({
            "status": "error",
            "error": str(e),
            "user": {"displayName": username.split("@")[0], "emailAddress": username, "avatarLocal": "", "jiraUrl": jira_url},
            "counts": {"total": 0, "in_progress": 0, "to_do": 0, "done": 0},
            "tasks": []
        }))

if __name__ == "__main__":
    main()
