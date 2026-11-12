#!/usr/bin/env python3
import os
import glob
import json
import time
import subprocess

CACHE_FILE = '/tmp/agy_quota_cache.json'
PERSISTENT_CACHE = os.path.expanduser('~/.cache/antigravity/agy_quota_cache.json')
SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
UPDATE_SCRIPT = os.path.join(SCRIPT_DIR, 'update_quota_cache.py')

def format_tokens(n):
    if n >= 1000000:
        return f"{n / 1000000.0:.1f}M"
    elif n >= 1000:
        return f"{n / 1000.0:.1f}k"
    return str(n)

def clean_quota_desc(d):
    if not d:
        return ''
    if '. If on a supported' in d:
        return d.split('. If on a supported')[0].strip() + '.'
    if 'If on a supported' in d:
        return d.split('If on a supported')[0].strip()
    return d

def read_quota_cache():
    now = time.time()
    cache_data = None

    for target in [CACHE_FILE, PERSISTENT_CACHE]:
        if os.path.exists(target):
            try:
                with open(target, 'r') as f:
                    cache_data = json.load(f)
                if cache_data and 'quotas' in cache_data:
                    break
            except Exception:
                cache_data = None

    need_refresh = False
    if not cache_data:
        need_refresh = True
    else:
        updated_at = cache_data.get('updated_at', 0)
        if now - updated_at > 90:  # Refresh every 90 seconds
            need_refresh = True

    if need_refresh:
        try:
            # Spawn update process detached so get_antigravity_status returns instantly
            subprocess.Popen([UPDATE_SCRIPT], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception:
            pass

    quotas = cache_data.get('quotas', {}) if cache_data else {}
    gemini_5h = quotas.get('Gemini Models_5h', {})
    gemini_wk = quotas.get('Gemini Models_weekly', {})
    claude_5h = quotas.get('Claude and GPT models_5h', {})
    claude_wk = quotas.get('Claude and GPT models_weekly', {})

    return {
        'gemini_5h_remaining': gemini_5h.get('remaining', 100),
        'gemini_5h_reset': gemini_5h.get('reset_time', ''),
        'gemini_5h_desc': clean_quota_desc(gemini_5h.get('description', '')),
        'gemini_weekly_remaining': gemini_wk.get('remaining', 100),
        'gemini_weekly_reset': gemini_wk.get('reset_time', ''),
        'gemini_weekly_desc': clean_quota_desc(gemini_wk.get('description', '')),
        'claude_5h_remaining': claude_5h.get('remaining', 100),
        'claude_5h_reset': claude_5h.get('reset_time', ''),
        'claude_5h_desc': clean_quota_desc(claude_5h.get('description', '')),
        'claude_weekly_remaining': claude_wk.get('remaining', 100),
        'claude_weekly_reset': claude_wk.get('reset_time', ''),
        'claude_weekly_desc': clean_quota_desc(claude_wk.get('description', ''))
    }

def get_status():
    brain_dir = os.path.expanduser('~/.gemini/antigravity-cli/brain')
    quota_info = read_quota_cache()

    default_res = {
        'conversation_count': 0,
        'latest_id': 'None',
        'active': False,
        'step_count': 0,
        'status': 'IDLE',
        'last_text': 'No active session',
        'context_tokens': 0,
        'context_limit': 1000000,
        'context_percent': 0.0,
        'context_tokens_str': '0k',
        'total_session_tokens': 0,
        'total_session_tokens_str': '0',
        **quota_info
    }

    if not os.path.exists(brain_dir):
        return default_res

    convos = [d for d in glob.glob(os.path.join(brain_dir, '*')) if os.path.isdir(d) and not os.path.basename(d).startswith('.')]
    if not convos:
        return default_res

    def get_conv_mtime(d):
        tf = os.path.join(d, '.system_generated', 'logs', 'transcript.jsonl')
        if os.path.exists(tf):
            return os.path.getmtime(tf)
        return os.path.getmtime(d)

    convos.sort(key=get_conv_mtime, reverse=True)
    latest_path = None
    for c in convos:
        tf = os.path.join(c, '.system_generated', 'logs', 'transcript.jsonl')
        if os.path.exists(tf) and os.path.getsize(tf) > 0:
            latest_path = c
            break

    if not latest_path:
        latest_path = convos[0]

    latest_id = os.path.basename(latest_path)
    latest_mtime = os.path.getmtime(latest_path)

    now = time.time()
    is_active = (now - latest_mtime) < 180  # active within 3 minutes

    step_count = 0
    status_str = "ACTIVE" if is_active else "IDLE"
    last_text = ""
    last_inp = 0
    last_cache = 0
    last_out = 0
    total_tokens = 0

    transcript_file = os.path.join(latest_path, '.system_generated', 'logs', 'transcript.jsonl')
    if os.path.exists(transcript_file):
        try:
            file_size = os.path.getsize(transcript_file)
            # High-performance reverse seek: read the tail (last 64KB) instead of scanning the full multi-MB file
            with open(transcript_file, 'rb') as f:
                seek_pos = max(0, file_size - 65536)
                f.seek(seek_pos)
                tail_lines = f.read().decode('utf-8', errors='ignore').strip().split('\n')

            last_obj = None
            for line in reversed(tail_lines):
                if not line.strip():
                    continue
                try:
                    obj = json.loads(line)
                    if last_obj is None:
                        last_obj = obj
                        step_count = obj.get('step_index', 0)
                    if obj.get('type') == 'PLANNER_RESPONSE' and last_inp == 0:
                        last_inp = obj.get('input_tokens', 0)
                        last_cache = obj.get('cache_read_tokens', 0)
                        last_out = obj.get('output_tokens', 0)
                        break
                except Exception:
                    pass

            if last_obj:
                status = last_obj.get('status', 'DONE')
                if status == 'RUNNING' or is_active:
                    status_str = "PROCESSING" if is_active else "IDLE"

                content = last_obj.get('content', '')
                if isinstance(content, str) and content.strip():
                    clean = content.strip().replace('\n', ' ')
                    last_text = clean[:80] + ('...' if len(clean) > 80 else '')
        except Exception:
            pass

    current_context = last_inp + last_cache
    context_limit = 1000000 # 1M context window limit for Gemini 3.x
    context_percent = round((current_context / float(context_limit)) * 100.0, 1)

    return {
        'conversation_count': len(convos),
        'latest_id': latest_id,
        'active': is_active,
        'step_count': step_count,
        'status': status_str,
        'last_text': last_text or 'Antigravity Ready',
        'context_tokens': current_context,
        'context_limit': context_limit,
        'context_percent': context_percent,
        'context_tokens_str': format_tokens(current_context),
        'total_session_tokens': total_tokens,
        'total_session_tokens_str': format_tokens(total_tokens),
        **quota_info
    }

if __name__ == '__main__':
    print(json.dumps(get_status()))
