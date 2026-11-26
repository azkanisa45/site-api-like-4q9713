# MINISTER UID PASS LIKE API SRC
# POWERED BY : @minister_69
# CHANNEL : @minister_6T9

from flask import Flask, request, jsonify
import asyncio
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad
from google.protobuf.json_format import MessageToJson
import binascii
import aiohttp
import requests
import json
import like_pb2
import like_count_pb2
import uid_generator_pb2
import time
from collections import defaultdict
from datetime import datetime, timezone, timedelta
import random
import os
import threading

import jwt
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# ============ CONFIG ==============
API_KEY        = "MNSTR"
JWT_API_URL    = "https://jakir-jwt-api-1.vercel.app/token"
JWT_API_KEY    = "MNSTR"

BD_CLIENT_URL  = "https://clientbp.ppmainecoonghj.com"
IND_CLIENT_URL = "https://clientbp.freefireind.in"
US_CLIENT_URL  = "https://client.us.freefiremobile.com"

OB55_USER_AGENT       = "UnityPlayer/2018.4.12f1 (UnityWebRequest/1.0, libcurl/8.5.0-DEV)"
OB55_X_GA_SV          = "1794159117"
OB55_X_UNITY_VERSION  = "2018.4.12f1"
OB55_RELEASE_VERSION  = "OB55"

KEY_LIMIT       = 90
TOKEN_CACHE_TTL = 7 * 60 * 60
BASE_DIR        = os.path.dirname(os.path.abspath(__file__))

# ===== RATE LIMIT (FAST + OPTIMAL) =====
BATCH_SIZE  = 15
BATCH_DELAY = 0.1
MAX_BATCH   = 2000

# ===== EARLY STOP (stagnation detection) =====
STAGNATION_CHECK_EVERY = 8
STAGNATION_THRESHOLD   = 3

# ===== LOGGING & AUTO-SAVE =====
DEBUG_LOG_FILE = os.path.join(BASE_DIR, "debug.txt")
RESULTS_DIR    = os.path.join(BASE_DIR, "results")
HISTORY_FILE   = os.path.join(BASE_DIR, "likes_history.json")

_log_lock = threading.Lock()


def init_debug_log():
    """Bersihkan debug.txt di awal session server."""
    try:
        with open(DEBUG_LOG_FILE, "w", encoding="utf-8") as f:
            f.write(f"===== SESSION STARTED: {datetime.now().isoformat()} =====\n")
    except Exception:
        pass


def log(*args, **kwargs):
    """Print ke terminal DAN tulis ke debug.txt secara real-time."""
    msg = " ".join(str(a) for a in args)
    print(msg, **kwargs)
    try:
        with _log_lock:
            with open(DEBUG_LOG_FILE, "a", encoding="utf-8") as f:
                f.write(msg + "\n")
                f.flush()
    except Exception:
        pass


# ============== APP =============
app = Flask(__name__)

TOKEN_CACHE  = {}
tracker      = defaultdict(lambda: [0, time.time()])
liked_cache  = defaultdict(set)

# ===== Global reusable aiohttp session =====
_HTTP_SESSION = None

def _get_session():
    global _HTTP_SESSION
    if _HTTP_SESSION is None or _HTTP_SESSION.closed:
        connector = aiohttp.TCPConnector(limit=100, limit_per_host=50, ttl_dns_cache=300)
        timeout   = aiohttp.ClientTimeout(total=20, connect=8)
        _HTTP_SESSION = aiohttp.ClientSession(connector=connector, timeout=timeout)
    return _HTTP_SESSION


# ============ HELPERS ============
def run_async(coro):
    try:
        asyncio.get_running_loop()
    except RuntimeError:
        return asyncio.run(coro)
    import concurrent.futures
    with concurrent.futures.ThreadPoolExecutor() as pool:#minister_69
        return pool.submit(asyncio.run, coro).result()


def get_today_midnight_timestamp():
    now = datetime.now()
    return datetime(now.year, now.month, now.day).timestamp()


def _account_file(server_name):
    if server_name == "IND":
        return os.path.join(BASE_DIR, "accounts_ind.json")
    elif server_name in {"BR", "US", "SAC", "NA"}:
        return os.path.join(BASE_DIR, "accounts_br.json")
    else:
        return os.path.join(BASE_DIR, "accounts_bd.json")


def load_accounts(server_name):
    filename = _account_file(server_name)

    if not os.path.exists(filename):
        fallback = os.path.join(BASE_DIR, "accounts_ind.json")
        log(f"⚠️ {os.path.basename(filename)} not found, trying accounts_ind.json")
        if not os.path.exists(fallback):
            log("❌ No account file found")
            return []
        filename = fallback

    accounts = []
    log(f"📂 Loading from: {os.path.basename(filename)} for server {server_name}")
    try:#minister_69
        with open(filename, "r", encoding="utf-8") as f:
            data = json.load(f)

        if not isinstance(data, list):
            log(f"❌ {os.path.basename(filename)} must be a JSON array []")
            return []

        for item in data:
            if not isinstance(item, dict):
                continue
            uid      = str(item.get("uid", "")).strip()
            password = str(item.get("password", "")).strip()
            if uid and password and uid.lower() != "uid" and password.lower() != "password":
                accounts.append({"uid": uid, "password": password})

    except json.JSONDecodeError as e:
        log(f"❌ Invalid JSON in {os.path.basename(filename)}: {e}")
        return []#minister_69
    except Exception as e:
        log(f"❌ Error loading accounts: {e}")
        return []

    log(f"✅ Total {len(accounts)} accounts loaded for {server_name}")
    return accounts


async def generate_jwt_token(uid, password):
    try:
        url = f"{JWT_API_URL}?key={JWT_API_KEY}&uid={uid}&password={password}"
        session = _get_session()
        async with session.get(url, timeout=aiohttp.ClientTimeout(total=10)) as response:
            if response.status == 200:
                data = await response.json()
                if isinstance(data, dict):
                    return data.get('jwt_token') or data.get('token')
    except asyncio.TimeoutError:
        pass
    except Exception as e:
        log(f"[JWT ERR] {e}")
    return None


async def get_valid_token(uid, password):
    if uid in TOKEN_CACHE:
        cached = TOKEN_CACHE[uid]
        remaining = (cached["expires_at"] - datetime.now(timezone.utc)).total_seconds()
        if remaining > 0:
            log(f"♻️ [CACHE HIT] UID {uid} — valid for {int(remaining)}s more")
            return cached["token"]
        else:
            log(f"⏰ [CACHE EXPIRED] UID {uid} — regenerating token")

    token = await generate_jwt_token(uid, password)
    if not token:
        return None

    TOKEN_CACHE[uid] = {
        "token": token,
        "expires_at": datetime.now(timezone.utc) + timedelta(seconds=TOKEN_CACHE_TTL),
    }#minister_69
    log(f"🆕 [CACHE STORED] UID {uid} — cached for 7 hours")
    return token


def encrypt_message(plaintext):
    key = b'Yg&tc%DEuh6%Zc^8'
    iv  = b'6oyZDr22E3ychjM%'
    cipher = AES.new(key, AES.MODE_CBC, iv)
    padded = pad(plaintext, AES.block_size)
    return binascii.hexlify(cipher.encrypt(padded)).decode('utf-8')


def enc(uid):
    message = uid_generator_pb2.uid_generator()
    fields  = list(message.DESCRIPTOR.fields)
    setattr(message, fields[0].name, int(uid))
    if len(fields) > 1:#minister_69
        setattr(message, fields[1].name, 1)
    return encrypt_message(message.SerializeToString())


def create_protobuf_message(user_id, region):
    message = like_pb2.like()
    message.uid = int(user_id)
    message.region = region
    return message.SerializeToString()


def decode_protobuf(binary):
    try:#minister_69
        items = like_count_pb2.Info()
        items.ParseFromString(binary)
        return items
    except Exception:
        return None


# ============== API CALLS ==============
def _get_headers(token):
    return {
        'User-Agent': OB55_USER_AGENT,
        'Accept': "*/*",
        'Accept-Encoding': "deflate, gzip",
        'X-GA-SV': OB55_X_GA_SV,
        'Authorization': f"Bearer {token}",
        'X-GA': "v1 1",
        'ReleaseVersion': OB55_RELEASE_VERSION,
        'Content-Type': "application/x-www-form-urlencoded",
        'X-Unity-Version': OB55_X_UNITY_VERSION,
    }


def _client_url(server_name):
    if server_name == "IND":
        return IND_CLIENT_URL
    elif server_name in {"BR", "US", "SAC", "NA"}:
        return US_CLIENT_URL
    else:
        return BD_CLIENT_URL


def get_player_info(encrypted_uid, server_name, token):
    try:
        edata = bytes.fromhex(encrypted_uid)
        url = f"{_client_url(server_name)}/GetPlayerPersonalShow"
        response = requests.post(url, data=edata, headers=_get_headers(token),
                                 verify=False, timeout=10)
        return decode_protobuf(response.content)
    except Exception:
        return None


def _like_url(server_name):
    return f"{_client_url(server_name)}/LikeProfile"


async def send_like(encrypted_uid, token, url):
    try:
        edata = bytes.fromhex(encrypted_uid)
        session = _get_session()
        async with session.post(url, data=edata, headers=_get_headers(token),
                                timeout=aiohttp.ClientTimeout(total=10)) as response:
            return response.status
    except asyncio.TimeoutError:
        return 408
    except Exception:
        return 500


async def process_account(target_uid, encrypted_uid, account, url, semaphore):
    async with semaphore:
        try:
            token = await get_valid_token(account['uid'], account['password'])
            if not token:
                return 500, account['uid'], "TOKEN_FAIL"

            status = await send_like(encrypted_uid, token, url)
            if status == 200:
                liked_cache[target_uid].add(account['uid'])
                return status, account['uid'], "OK"
            return status, account['uid'], f"HTTP_{status}"
        except Exception as e:
            return 500, account['uid'], f"ERR:{type(e).__name__}"


def _check_current_likes(encrypted_uid, server_name, token):
    info = get_player_info(encrypted_uid, server_name, token)
    if info is None:
        return None
    try:
        data = json.loads(MessageToJson(info))
        return int(data['AccountInfo'].get('Likes', 0))
    except Exception:
        return None


async def _check_current_likes_async(encrypted_uid, server_name, token):
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(
        None, _check_current_likes, encrypted_uid, server_name, token
    )


# ============== AUTO-SAVE ==============
def save_result(payload):
    """Simpan hasil ke results/UID_SERVER_timestamp.json + append ke history."""
    try:
        os.makedirs(RESULTS_DIR, exist_ok=True)
        ts = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
        per_file = os.path.join(
            RESULTS_DIR,
            f"{payload['TargetUID']}_{payload['Server']}_{ts}.json"
        )
        with open(per_file, "w", encoding="utf-8") as f:
            json.dump(payload, f, indent=2, ensure_ascii=False)

        # Append ringkasan ke history
        summary = {
            "timestamp":       payload["Timestamp"],
            "target_uid":      payload["TargetUID"],
            "target_nickname": payload["PlayerNickname"],
            "server":          payload["Server"],
            "before_like":     payload["LikesbeforeCommand"],
            "after_like":      payload["LikesafterCommand"],
            "likes_given":     payload["LikesGivenByAPI"],
            "status":          payload["Status"],
            "success":         payload["Success"],
            "failed":          payload["Failed"],
            "elapsed":         payload["ElapsedSeconds"],
            "stopped_early":   payload["StoppedEarly"],
        }

        history = []
        if os.path.exists(HISTORY_FILE):
            try:
                with open(HISTORY_FILE, "r", encoding="utf-8") as f:
                    history = json.load(f)
                if not isinstance(history, list):
                    history = []
            except Exception:
                history = []

        history.append(summary)
        history = history[-1000:]

        with open(HISTORY_FILE, "w", encoding="utf-8") as f:
            json.dump(history, f, indent=2, ensure_ascii=False)

        return os.path.relpath(per_file, BASE_DIR)
    except Exception as e:
        log(f"⚠️ [AUTO-SAVE ERROR] {e}")
        return None


async def send_all_likes(target_uid, server_name, url, check_token, before_like):
    protobuf_message = create_protobuf_message(target_uid, server_name)
    encrypted_uid    = encrypt_message(protobuf_message)

    accounts = load_accounts(server_name)
    if not accounts:
        return {'success': 0, 'failed': 0, 'total': 0,
                'already_liked': 0, 'fresh_used': 0, 'elapsed': 0.0,
                'stopped_early': False,
                'success_uids': [], 'failed_detail': []}

    already_liked  = liked_cache.get(target_uid, set())
    fresh_accounts = [acc for acc in accounts if acc['uid'] not in already_liked]

    log(f"📊 Total: {len(accounts)} | Fresh: {len(fresh_accounts)} | Liked: {len(already_liked)}")

    if not fresh_accounts:
        return {'success': 0, 'failed': 0, 'total': len(accounts),
                'already_liked': len(already_liked), 'fresh_used': 0, 'elapsed': 0.0,
                'stopped_early': False,
                'success_uids': [], 'failed_detail': []}

    random.shuffle(fresh_accounts)
    batch = fresh_accounts[:MAX_BATCH]

    semaphore = asyncio.Semaphore(BATCH_SIZE)

    total_batches = (len(batch) + BATCH_SIZE - 1) // BATCH_SIZE
    log(f"⚡ Processing {len(batch)} accounts in {total_batches} batches "
        f"(size={BATCH_SIZE}, delay={BATCH_DELAY}s)")

    successful    = 0
    failed        = 0
    success_uids  = []
    failed_detail = []
    processed     = 0
    stopped_early = False

    last_observed_likes = before_like
    stagnation_streak   = 0

    start_time = time.time()

    for bi, batch_start in enumerate(range(0, len(batch), BATCH_SIZE), start=1):
        chunk = batch[batch_start:batch_start + BATCH_SIZE]
        tasks = [process_account(target_uid, encrypted_uid, acc, url, semaphore)
                 for acc in chunk]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        for r in results:
            processed += 1
            if isinstance(r, tuple) and len(r) >= 3 and r[0] == 200:
                successful += 1
                success_uids.append(r[1])
            else:
                failed += 1
                if isinstance(r, tuple) and len(r) >= 3:
                    failed_detail.append({"uid": r[1], "reason": r[2]})
                else:
                    failed_detail.append({"uid": "unknown", "reason": str(r)})

        # ===== Early stop check =====
        if bi % STAGNATION_CHECK_EVERY == 0 and check_token and processed < len(batch):
            current_likes = await _check_current_likes_async(
                encrypted_uid, server_name, check_token
            )
            if current_likes is not None:
                delta = current_likes - last_observed_likes
                if delta <= 0:
                    stagnation_streak += 1
                    log(f"   🔍 Stagnation check #{stagnation_streak}: "
                        f"likes={current_likes} (no increase)")
                    if stagnation_streak >= STAGNATION_THRESHOLD:
                        log(f"   🛑 Like stagnan {STAGNATION_THRESHOLD}× berturut-turut — "
                            f"stop early! (hemat {len(batch) - processed} akun)")
                        stopped_early = True
                        break
                else:
                    stagnation_streak = 0
                    last_observed_likes = current_likes
                    log(f"   ✨ Likes naik +{delta} → total {current_likes}")

        if bi % 5 == 0:
            pct = int(processed * 100 / len(batch))
            log(f"   ⏳ {processed}/{len(batch)} ({pct}%) | ✅ {successful} | ❌ {failed}")

        await asyncio.sleep(BATCH_DELAY)

    elapsed = round(time.time() - start_time, 1)

    # ================= TERMINAL REPORT =================
    log("\n" + "=" * 68)
    log(f"🎯 TARGET UID : {target_uid}")
    log(f"🌍 SERVER     : {server_name}")
    log(f"{'⚠️  EARLY STOPPED — like stagnan (FF cap reached)' if stopped_early else '✅ FULL RUN COMPLETED'}")
    log("=" * 68)

    log(f"\n✅ SUCCESSFUL ACCOUNTS ({successful}):")
    if success_uids:
        for i, acc_uid in enumerate(success_uids, 1):
            log(f"   [{i:>4}] {acc_uid}  ✅")
    else:
        log("   (no successful accounts)")

    log(f"\n❌ FAILED ACCOUNTS ({failed}):")
    if failed_detail:
        for i, item in enumerate(failed_detail, 1):
            log(f"   [{i:>4}] {item['uid']}  ❌  ({item['reason']})")
    else:
        log("   (no failed accounts)")

    log("\n" + "─" * 68)
    log("📊 SUMMARY")
    log("─" * 68)
    log(f"   📁 Total akun dimuat           : {len(accounts)}")
    log(f"   🔄 Total akun sudah pernah like: {len(already_liked)}")
    log(f"   🚀 Akun diproses               : {processed}/{len(batch)}"
        f"{' (stopped early)' if stopped_early else ''}")
    log(f"   ✅ Total akun HTTP 200         : {successful}")
    log(f"   ❌ Total akun gagal            : {failed}")
    log(f"   ⏱️  Waktu eksekusi             : {elapsed}s")
    log("─" * 68)
    log(f"   🎯 LIKE DIBERIKAN KE TARGET {target_uid} : +{successful}")
    log("=" * 68 + "\n")

    return {
        'success':       successful,
        'failed':        failed,
        'total':         len(accounts),
        'already_liked': len(already_liked),
        'fresh_used':    processed,
        'elapsed':       elapsed,
        'stopped_early': stopped_early,
        'success_uids':  success_uids,
        'failed_detail': failed_detail,
    }


# ============== ROUTES ================
@app.route('/', methods=['GET'])
def home():
    return jsonify({
        "status": "online",
        "api": "MINISTER UID PASS LIKE API (OB55)",
        "token_cache_ttl": f"{TOKEN_CACHE_TTL}s (7 hours)",
        "rate_limit": {
            "batch_size":  BATCH_SIZE,
            "batch_delay": f"{BATCH_DELAY}s",
            "early_stop_after_stagnant_checks": STAGNATION_THRESHOLD,
        },
        "auto_save": {
            "per_request": f"results/UID_SERVER_timestamp.json",
            "history":     "likes_history.json",
        },
        "debug_log": "debug.txt (real-time)",
        "credit": "@minister_69",
        "channel": "@minister_6T9",
        "endpoints": {
            "/like": "?uid=UID&server_name=BD&key=*****",
            "/reset-cache": "?key=*****",
            "/history": "?limit=20&key=*****",
        },
    })


@app.route('/like', methods=['GET'])
def handle_requests():
    uid         = request.args.get("uid")
    server_name = request.args.get("server_name", "").upper()
    key         = request.args.get("key")
    client_ip   = request.remote_addr or "unknown"

    if key != API_KEY:
        return jsonify({"error": "Invalid or missing API key 🔑"}), 403#minister_69
    if not uid or not server_name:
        return jsonify({"error": "UID and server_name are required"}), 400

    valid_servers = ["IND", "BR", "US", "SAC", "NA", "BD", "RU"]
    if server_name not in valid_servers:
        return jsonify({"error": f"Invalid server. Use: {valid_servers}"}), 400

    accounts = load_accounts(server_name) or load_accounts("IND")
    if not accounts:
        return jsonify({"error": f"No accounts found for server {server_name}"}), 500

    # ===== Daily limit =====
    today_midnight = get_today_midnight_timestamp()
    count, last_reset = tracker[client_ip]
    if last_reset < today_midnight:
        tracker[client_ip] = [0, time.time()]
        count = 0
    if count >= KEY_LIMIT:
        return jsonify({"error": "Daily limit reached",
                        "remains": f"(0/{KEY_LIMIT})"}), 429

    # ===== Get a check token =====
    check_token = None
    for account in accounts[:5]:
        check_token = run_async(get_valid_token(account['uid'], account['password']))
        if check_token:
            log(f"✅ Token generated with UID: {account['uid']}")
            break
    if not check_token:
        return jsonify({"error": "Token generation failed - no valid accounts"}), 500

    encrypted_uid = enc(uid)

    # ===== Before like =====
    before = get_player_info(encrypted_uid, server_name, check_token)
    if before is None:
        return jsonify({"error": "Invalid UID or server", "status": 0}), 200
    try:
        before_data = json.loads(MessageToJson(before))
        before_like = int(before_data['AccountInfo'].get('Likes', 0))
    except Exception:
        return jsonify({"error": "Data parsing failed", "status": 0}), 200

    # ===== Send likes =====
    like_url    = _like_url(server_name)
    like_result = run_async(send_all_likes(uid, server_name, like_url,
                                          check_token, before_like))#minister_69

    # ===== After like =====
    after = get_player_info(encrypted_uid, server_name, check_token)
    if after is None:
        return jsonify({"error": "Could not verify likes after command",
                        "status": 0}), 200

    try:
        after_data   = json.loads(MessageToJson(after))
        after_like   = int(after_data['AccountInfo']['Likes'])
        player_id    = int(after_data['AccountInfo']['UID'])
        player_name  = str(after_data['AccountInfo']['PlayerNickname'])

        like_given = after_like - before_like
        status     = 1 if like_given != 0 else 2

        if like_given > 0:
            tracker[client_ip][0] += 1
            count += 1

        remains = KEY_LIMIT - count

        # ===== AUTO-SAVE (full detail, termasuk UID list) =====
        saved_path = save_result({
            "Timestamp":            datetime.now().isoformat(),
            "TargetUID":            uid,
            "PlayerNickname":       player_name,
            "Server":               server_name,
            "LikesbeforeCommand":   before_like,
            "LikesafterCommand":    after_like,
            "LikesGivenByAPI":      like_given,
            "Status":               status,
            "Remains":              f"({remains}/{KEY_LIMIT})",
            "AccountsLoaded":       like_result.get('total', 0),
            "AlreadyLiked":         like_result.get('already_liked', 0),
            "FreshUsed":            like_result.get('fresh_used', 0),
            "Success":              like_result.get('success', 0),
            "Failed":               like_result.get('failed', 0),
            "ElapsedSeconds":       like_result.get('elapsed', 0.0),
            "StoppedEarly":         like_result.get('stopped_early', False),
            "SuccessUIDs":          like_result.get('success_uids', []),
            "FailedUIDs":           like_result.get('failed_detail', []),
            "ClientIP":             client_ip,
        })
        log(f"💾 [AUTO-SAVE] Result saved → {saved_path}")

        return jsonify({
            "LikesGivenByAPI":    like_given,
            "LikesafterCommand":  after_like,
            "LikesbeforeCommand": before_like,
            "PlayerNickname":     player_name,
            "UID":                player_id,
            "status":             status,
            "remains":            f"({remains}/{KEY_LIMIT})",

            "AccountsLoaded":   like_result.get('total', 0),
            "AlreadyLiked":     like_result.get('already_liked', 0),
            "FreshUsed":        like_result.get('fresh_used', 0),
            "Success":          like_result.get('success', 0),
            "Failed":           like_result.get('failed', 0),
            "ElapsedSeconds":   like_result.get('elapsed', 0.0),
            "StoppedEarly":     like_result.get('stopped_early', False),
            "SavedTo":          saved_path,
        })
    except Exception as e:
        return jsonify({"error": str(e), "status": 0}), 500


@app.route('/history', methods=['GET'])
def history():
    if request.args.get("key") != API_KEY:
        return jsonify({"error": "Invalid key"}), 403
    limit = int(request.args.get("limit", 20))
    limit = max(1, min(limit, 200))

    try:
        if not os.path.exists(HISTORY_FILE):
            return jsonify({"count": 0, "history": []})
        with open(HISTORY_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
        if not isinstance(data, list):
            data = []
        recent = data[-limit:][::-1]
        return jsonify({"count": len(recent), "history": recent})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/reset-cache', methods=['GET'])
def reset_cache():
    if request.args.get("key") != API_KEY:
        return jsonify({"error": "Invalid key"}), 403
    liked_cache.clear()
    return jsonify({"message": "Cache cleared", "credit": "@minister_69"})#minister_69


# ============= ENTRY POINT ==============
if __name__ == '__main__':
    init_debug_log()

    log("🚀 Server started - Smart Like System! (OB55 | 7H Token Cache)")
    log(f"⏱️  Token Cache TTL = {TOKEN_CACHE_TTL}s (7 hours)")
    log(f"⚡ Batch size = {BATCH_SIZE} | Delay = {BATCH_DELAY}s | Max = {MAX_BATCH}")
    log(f"🛑 Early stop: {STAGNATION_THRESHOLD}× stagnan "
        f"(cek tiap {STAGNATION_CHECK_EVERY} batch)")
    log(f"📝 Debug log → {os.path.basename(DEBUG_LOG_FILE)} (real-time)")
    log(f"💾 Auto-save  → {os.path.basename(RESULTS_DIR)}/ + "
        f"{os.path.basename(HISTORY_FILE)}")
    log("📁 Account files:")
    log("   - accounts_ind.json (IND)")
    log("   - accounts_br.json  (BR/US/SAC/NA)")
    log("   - accounts_bd.json  (BD/RU)")
    app.run(host='0.0.0.0', port=5069, debug=False, use_reloader=False)

# MINISTER UID PASS LIKE API SRC
# POWERED BY : @minister_69
# CHANNEL : @minister_6T9