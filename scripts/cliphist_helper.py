#!/usr/bin/env python3
import os
import sys
import subprocess
import json
import re

CACHE_DIR = "/tmp/cliphist_cache"
os.makedirs(CACHE_DIR, exist_ok=True)

def get_list(limit=80):
    res = subprocess.run(["cliphist", "list"], capture_output=True, text=True)
    if res.returncode != 0:
        return []

    lines = res.stdout.strip().splitlines()[:limit]
    items = []

    for line in lines:
        parts = line.split("\t", 1)
        if len(parts) != 2:
            continue
        cid, text = parts[0], parts[1]
        is_bin = text.startswith("[[ binary data")

        item = {
            "id": cid,
            "text": text,
            "type": "text",
            "thumb": "",
            "meta": ""
        }

        if is_bin:
            item["type"] = "image"
            m = re.search(r'\[\[ binary data ([\d\.]+ \w+) (\w+) (\d+x\d+) \]\]', text)
            if m:
                item["meta"] = f"{m.group(3)} • {m.group(1)} {m.group(2).upper()}"
            else:
                item["meta"] = "Image"
            # Decode image into cache for immediate thumbnail and preview
            cache_file = os.path.join(CACHE_DIR, f"{cid}.png")
            if not os.path.exists(cache_file):
                try:
                    with open(cache_file, "wb") as f:
                        subprocess.run(["cliphist", "decode", cid], stdout=f, timeout=2)
                except Exception:
                    pass
            if os.path.exists(cache_file):
                item["thumb"] = cache_file
        elif text.startswith(("http://", "https://")):
            item["type"] = "url"
            item["meta"] = "URL Link"
        elif any(k in text for k in ["def ", "function", "class ", "import ", "{", "}", "const ", "var ", "export ", "public ", "private ", "<!DOCTYPE", "<html"]):
            item["type"] = "code"
            item["meta"] = "Code Snippet"
        else:
            item["type"] = "text"
            item["meta"] = f"{len(text)} chars"

        items.append(item)

    return items

def decode_image(cid):
    cache_file = os.path.join(CACHE_DIR, f"{cid}.png")
    if not os.path.exists(cache_file):
        with open(cache_file, "wb") as f:
            subprocess.run(["cliphist", "decode", cid], stdout=f)
    print(cache_file if os.path.exists(cache_file) else "")

def decode_text(cid):
    res = subprocess.run(["cliphist", "decode", cid], capture_output=True, text=True, errors="replace")
    sys.stdout.write(res.stdout)

def copy_item(cid):
    # Decode and pipe into wl-copy for both clipboard and primary selection
    p1 = subprocess.Popen(["cliphist", "decode", cid], stdout=subprocess.PIPE)
    subprocess.run(["wl-copy"], stdin=p1.stdout)
    p2 = subprocess.Popen(["cliphist", "decode", cid], stdout=subprocess.PIPE)
    subprocess.run(["wl-copy", "--primary"], stdin=p2.stdout)

def delete_item(cid, raw_text):
    p = subprocess.Popen(["cliphist", "delete"], stdin=subprocess.PIPE, text=True)
    p.communicate(f"{cid}\t{raw_text}\n")
    cache_file = os.path.join(CACHE_DIR, f"{cid}.png")
    if os.path.exists(cache_file):
        try:
            os.remove(cache_file)
        except Exception:
            pass

def wipe_all():
    subprocess.run(["cliphist", "wipe"])
    for f in os.listdir(CACHE_DIR):
        try:
            os.remove(os.path.join(CACHE_DIR, f))
        except Exception:
            pass

def main():
    if len(sys.argv) < 2:
        items = get_list()
        print(json.dumps(items))
        return

    cmd = sys.argv[1]
    if cmd == "list":
        limit = int(sys.argv[2]) if len(sys.argv) > 2 else 80
        items = get_list(limit)
        print(json.dumps(items))
    elif cmd == "decode-image":
        decode_image(sys.argv[2])
    elif cmd == "decode-text":
        decode_text(sys.argv[2])
    elif cmd == "copy":
        copy_item(sys.argv[2])
    elif cmd == "delete":
        cid = sys.argv[2]
        raw_text = sys.argv[3] if len(sys.argv) > 3 else ""
        delete_item(cid, raw_text)
    elif cmd == "wipe":
        wipe_all()

if __name__ == "__main__":
    main()
