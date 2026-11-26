# 🔥 MINISTER UID PASS LIKE API (OB55)

> **Credit:** @minister_69  
> **Channel:** @minister_6T9  
> **Like Group:** @minister_likes  
> **Status:** OB55 Updated | JSON Accounts | Fully Async | Smart Like System

A powerful **Free Fire Like API** built with Flask that sends likes to players using a pool of accounts and JWT tokens. Now supports **JSON-based account storage** with multi-region support (BD, IND, BR, US, SAC, NA, RU).

---

## ✨ Features

- ⚡ **Fully Async** — Uses `aiohttp` + `asyncio.gather` for concurrent requests
- 🚀 **Smart Like System** — Tracks which accounts already liked → uses only fresh accounts
- 🔑 **JWT Auto-Generation** — Fetches tokens from JWT API automatically
- 🎯 **Multi-Region Support** — BD, IND, BR, US, SAC, NA, RU
- 📦 **JSON Account Storage** — `accounts_*.json` instead of `.txt`
- 🛡️ **API Key Protected** — Only authorized keys can send likes
- 📊 **Daily Limit Tracker** — Per-IP limit (90 requests/day by default)
- 🧠 **Token Cache** — Reuses valid tokens (7-day expiry) to save API calls
- 🔐 **Already-Liked Memory** — Prevents the same account from liking twice

---

## 📦 Installation (Local)

### 1. Clone the repository
```bash
git clone https://github.com/your-username/like-api.git
cd like-api
```

2. Install dependencies

```bash
pip install -r requirements.txt
```

3. Prepare JSON account files

Create these files in the root folder:

accounts_bd.json

```json
[
  {
    "uid": Paste_Your_UID,
    "password": "Paste_Your_Password"
  },
  {
    "uid": Paste_Your_UID,
    "password": "Paste_Your_Password"
  }
]
```

accounts_ind.json

```json
[
  {
    "uid": Paste_Your_UID,
    "password": "Paste_Your_Password"
  },
  {
    "uid": Paste_Your_UID,
    "password": "Paste_Your_Password"
  }
]
```

accounts_br.json

```json
[
  {
    "uid": Paste_Your_UID,
    "password": "Paste_Your_Password"
  },
  {
    "uid": Paste_Your_UID,
    "password": "Paste_Your_Password"
  }
]
```

Format rules:

· Root must be a JSON array []
· Each item must have "uid" (int or string) and "password" (string)
· Empty array [] is valid — API will fallback to accounts_ind.json

4. Configure JWT API

In app.py:

```python
JWT_API_URL = "https://jakir-jwt-api-1.vercel.app/token"
JWT_API_KEY = "MNSTR"
```

5. Run the server

```bash
python app.py
```

Server starts on http://localhost:5069

---

🚀 Deployment (Vercel)

1. Push all files to a GitHub repository
2. Import the repository on Vercel
3. Vercel auto-detects app.py (via vercel.json)
4. Your API will be live at https://your-project.vercel.app

Required Files for Vercel

```
├── app.py
├── vercel.json
├── requirements.txt
├── like_pb2.py
├── like_count_pb2.py
├── uid_generator_pb2.py
├── accounts_bd.json
├── accounts_ind.json
├── accounts_br.json
└── README.md
```

vercel.json

```json
{
    "version": 2,
    "builds": [
        {
            "src": "./app.py",
            "use": "@vercel/python",
            "config": { "runtime": "python3.8" }
        }
    ],
    "routes": [
        { "src": "/(.*)", "dest": "/app.py" }
    ]
}
```

⚠️ No wsgi.py or index.py needed — everything is in app.py.

---

🔗 API Endpoints

GET /like

Sends likes to a target player.

Parameters:

Parameter Type Required Description
uid string ✅ Yes Target player's UID
server_name string ✅ Yes BD / IND / BR / US / SAC / NA / RU
key string ✅ Yes API Key (must be MNSTR)

Sample Request:

```
https://your-api.vercel.app/like?uid=1776450092&server_name=BD&key=MNSTR
```

Success Response:

```json
{
  "LikesGivenByAPI": 25,
  "LikesafterCommand": 46407,
  "LikesbeforeCommand": 46382,
  "PlayerNickname": "JAKIRㅤVAIㅤP2",
  "UID": 1776450092,
  "status": 1,
  "remains": "(89/90)"
}
```

Response Fields:

Field Description
LikesGivenByAPI Number of likes added
LikesafterCommand Total likes after the operation
LikesbeforeCommand Total likes before the operation
PlayerNickname Player's in-game name
UID Player's UID
status 1 = Success / 2 = No change / 0 = Fail
remains Remaining API calls today

Error Response:

```json
{
  "error": "Invalid UID or server",
  "status": 0
}
```

---

GET /reset-cache

Clears the already-liked cache.

Parameters:

Parameter Type Required Description
key string ✅ Yes API Key (must be MNSTR)

Sample Request:

```
https://your-api.vercel.app/reset-cache?key=MNSTR
```

Response:

```json
{
  "message": "Cache cleared",
  "credit": "@minister_69"
}
```

---

GET /

Health check / info endpoint.

Response:

```json
{
  "status": "online",
  "api": "MINISTER UID PASS LIKE API (OB55)",
  "account_format": "JSON",
  "credit": "@minister_69",
  "channel": "@minister_6T9",
  "endpoints": {
    "/like": "?uid=UID&server_name=BD&key=MNSTR",
    "/reset-cache": "?key=MNSTR"
  }
}
```

---

🧠 How It Works

```
User Request
    ↓
Load accounts from accounts_*.json (based on server_name)
    ↓
Generate JWT tokens (cached per account)
    ↓
Fetch target's current likes (GetPlayerPersonalShow)
    ↓
Send up to 2000 parallel like requests (25 concurrent via semaphore)
    ↓
Fetch updated likes (verify result)
    ↓
Return JSON response
```

Optimizations

1. Token Caching — JWT tokens cached per UID until near expiry
2. Liked Cache — Accounts that already liked a UID are skipped
3. Concurrent Requests — Up to 25 parallel like requests (semaphore)
4. JSON Account Loading — Fast parsing with error handling
5. Daily Tracker — Prevents abuse per IP

---

📂 Project Structure

```
like-api/
│
├── app.py                  # Main Flask app (single file)
├── vercel.json             # Vercel entry point
├── requirements.txt        # Dependencies
├── README.md
│
├── like_pb2.py             # Protobuf: like
├── like_count_pb2.py       # Protobuf: player info
├── uid_generator_pb2.py    # Protobuf: uid generator
│
├── accounts_bd.json        # BD / RU accounts
├── accounts_ind.json       # IND accounts
└── accounts_br.json        # BR / US / SAC / NA accounts
```

---

📋 requirements.txt

```
Flask[async]
requests
aiohttp
googleapis-common-protos
pycryptodome
protobuf
Werkzeug
PyJWT
urllib3
```

---

📝 JSON Account Format

Each accounts_*.json file must be a JSON array of objects:

```json
[
  {
    "uid": Paste_Your_UID,
    "password": "Paste_Your_Password"
  },
  {
    "uid": Paste_Your_UID,
    "password": "Paste_Your_Password"
  }
]
```

Rules:

· ✅ Root must be [] (array)
· ✅ Each item must have uid and password keys
· ✅ uid can be integer or string
· ❌ Not valid: object {}, plain text, or missing keys

---

🧪 Testing Locally

After starting the server, you should see:

```
🚀 Server started - Smart Like System! (OB55 | JSON Accounts)
📁 Account files:
   - accounts_ind.json (IND)
   - accounts_br.json  (BR/US/SAC/NA)
   - accounts_bd.json  (BD/RU)
 * Running on http://0.0.0.0:5069
```

Then hit:

```bash
curl "http://localhost:5069/like?uid=1776450092&server_name=BD&key=MNSTR"
```

Look for logs:

```
📂 Loading from: accounts_bd.json for server BD
✅ Total 25 accounts loaded for BD
✅ Token generated with UID: 4436290901
📊 Total: 25 | Fresh: 25 | Liked: 0
```


---

🛡️ Disclaimer

This project is for educational purposes only. Using this to send likes or interact with Free Fire servers may violate Garena's Terms of Service. Use at your own risk.

---

📞 Support

· Telegram: @minister_69
· Channel: @minister_6T9
· Like Group: @minister_likes

---

© 2026 @minister_69 — All rights reserved.