# eformsign API — Authentication & Tokens

## Prerequisites

### Required Information
- **Company ID**: Admin console > Company Management > Company Info
- **Member ID**: Company Management > Company Info > Details
- **API Key**: Connect > API/Webhook > API Key Management > Create API Key
  - Enter alias and application name
  - Select verification type: Bearer Token / Basic Authentication / eformsign Signature
- **Template ID**: `form_id` parameter in the template settings page URL
- **Document ID**: Add the column in the document list view to display it

---

## Base URL

| Purpose | URL |
|---------|-----|
| Issue Access Token only | `https://api.eformsign.com/v2.0` |
| All other APIs | `{api_key.company.api_url}` from Access Token response + `/v2.0` |

> Always use the `api_url` value returned in the Access Token response as the base for subsequent calls — do not hardcode a domain.

---

## Issue Access Token ✅ Swagger Official

```
POST https://api.eformsign.com/v2.0/api_auth/access_token
```

The `eformsign_signature` header format differs by the API key's verification type:

### Bearer Token method

**Headers:**
```
eformsign_signature: Bearer {user-registered token}
Authorization: Bearer {Base64-encoded API key ID}
Content-Type: application/json
```

> `{user-registered token}`: the token value the user manually enters when creating the API key in the Admin Console. This is **not** the API key ID — it is a separate secret value defined by the user at API key creation time.

### Basic Authentication method

**Headers:**
```
eformsign_signature: Basic {Base64("{API key ID}:{API key value}")}
Authorization: Bearer {Base64-encoded API key ID}
Content-Type: application/json
```

> `Base64("{ID}:{value}")` — colon-delimited concatenation of the API key ID and API key value, Base64-encoded

### eformsign Signature method

**Headers:**
```
eformsign_signature: {SHA256withECDSA signature hex}
Authorization: Bearer {Base64-encoded API key ID}
Content-Type: application/json
```

> See the [Generating a Signature](#generating-a-signature) section below for how to construct the signature hex string.

**Body (all three methods):**
```json
{
  "execution_time": 1234567890000,
  "member_id": "user@example.com"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| execution_time | integer (int64) | Y | Current time as 13-digit ms timestamp. Must arrive within ±30s of server time |
| member_id | string | N | Member ID (email) to issue token for. Defaults to API key owner |

**Response:**
```json
{
  "api_key": {
    "name": "app_name",
    "alias": "alias",
    "company": {
      "id": "company_id",
      "name": "Company Name",
      "api_url": "https://kr-api.eformsign.com"
    }
  },
  "oauth_token": {
    "token_type": "JWT",
    "access_token": "eyJ...",
    "refresh_token": "yyy...",
    "expires_in": 3600
  }
}
```

> Save these values from the response:
> - `api_key.company.api_url` — base URL for all subsequent API calls
> - `oauth_token.access_token` — used in `Authorization: Bearer` header
> - `oauth_token.refresh_token` — used to renew the access token

> **⚠️ Do NOT hardcode the API base URL** (e.g. `"https://api.eformsign.com"`). Always use the `api_url` from the token response — it may differ per company/region.

**Python example — full flow (issue token → extract api_url → call API):**
```python
import requests

def issue_access_token(api_key_id: str, signature_hex: str, execution_time: int) -> dict:
    url = "https://api.eformsign.com/v2.0/api_auth/access_token"
    headers = {
        "eformsign_signature": signature_hex,
        "Authorization": f"Bearer {api_key_id}",
        "Content-Type": "application/json",
    }
    body = {"execution_time": execution_time, "member_id": "user@example.com"}
    resp = requests.post(url, json=body, headers=headers)
    resp.raise_for_status()
    data = resp.json()
    return {
        "api_url": data["api_key"]["company"]["api_url"],  # use this for all subsequent calls
        "access_token": data["oauth_token"]["access_token"],
        "refresh_token": data["oauth_token"]["refresh_token"],
    }

# After issuing the token:
token_info = issue_access_token(API_KEY_ID, signature_hex, execution_time)
api_url = token_info["api_url"]          # e.g. "https://kr-api.eformsign.com"
access_token = token_info["access_token"]

# Use api_url (NOT a hardcoded URL) for all subsequent API calls:
resp = requests.post(
    f"{api_url}/v2.0/api/list_document",
    json={"limit": "20", "page": 1},
    headers={"Authorization": f"Bearer {access_token}"},
)
```

---

## Refresh Access Token ✅ Swagger Official

```
POST {api_url}/v2.0/api_auth/refresh_token?refresh_token={refresh_token}
```

**Headers:**
```
Authorization: Bearer {current_access_token}
Content-Type: application/json
```

> `refresh_token` is passed as a **query parameter**, not in the request body. The body should be empty.

**Response:**
```json
{
  "oauth_token": {
    "token_type": "JWT",
    "access_token": "eyJ...",
    "refresh_token": "yyy...",
    "expires_in": 3600
  }
}
```

> **⚠️ Save both tokens from the response** — the server issues a new `refresh_token` on every renewal. If you only save `access_token` and discard the new `refresh_token`, the next refresh will fail.

**Python example:**
```python
import requests

def refresh_access_token(api_url: str, access_token: str, refresh_token: str) -> dict:
    url = f"{api_url}/v2.0/api_auth/refresh_token"
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
    }
    resp = requests.post(url, params={"refresh_token": refresh_token}, headers=headers)
    resp.raise_for_status()
    token = resp.json()["oauth_token"]
    # Always save both — server issues a new refresh_token each time
    access_token = token["access_token"]
    refresh_token = token["refresh_token"]
    return {"access_token": access_token, "refresh_token": refresh_token}
```

---

## Error Codes & Status Codes

### Common Error Response
```json
{
  "code": "string",
  "ErrorMessage": "string",
  "execution_time": 1700000000000
}
```

> ⚠️ **Two known server quirks when parsing error responses:**
>
> 1. **HTTP 200 with error body**: Token expiry (`4030002`) can be returned with HTTP status 200 — not 401. Always check the response body `code` field even on 200 responses.
>
> 2. **Inconsistent error message field**: Some endpoints use `ErrorMessage`, others use `message`. Check both fields when parsing error responses.

### Error Codes
| Code | Meaning |
|------|---------|
| 4000002 | Auth time expired (request arrived >30s after signing) |
| 4000004 | No document selected (POST /api/documents/{id}/re_request_outsider) |
| 4000070 | Member contact is missing (PATCH /api/members — contact field required) |
| 4000074 | Invalid id or password (PATCH/DELETE /api/members) |
| 4000115 | Domain access restriction (POST /api/documents/external — configure allowed domains in Admin Console > Connect > API/Webhook) |
| 4000125 | Administrator account cannot be modified (PATCH /api/members) |
| 4000166 | Document already cancelled |
| 4000169 | Not authorized to cancel/revoke document |
| 4010002 | Invalid refresh token (POST /api_auth/refresh_token) |
| 4030001 | Invalid API key (POST /api_auth/access_token) |
| 4030002 | Invalid Access Token |
| 4030004 | eformsign signature verification failed |
| 4030009 | Access denied — insufficient template permissions (DELETE /api/forms) |
| 4030039 | API key encoding error (POST /api/documents/external — use API Key Base64 Bearer auth, not Access Token) |
| 5000001–3 | Internal server error |

### Document status_type Codes
| Code | Meaning |
|------|---------|
| 001 | Draft (temp save) |
| 002 | In progress |
| 003 | Completed |
| 011 | Decline requested |
| 021 | Declined by internal member |
| 030 | Sent to external recipient |
| 031 | Declined by external recipient |
| 032 | Accepted by external recipient |
| 040 | Cancellation requested |
| 042 | Cancelled |

### step_type Codes
| Code | Meaning |
|------|---------|
| 01 | Internal signer |
| 02 | Internal approver |
| 03 | External recipient (legacy) |
| 04 | Internal recipient (legacy) |
| 05 | External signer |
| 06 | Designated internal member |

---

## Generating a Signature

Required for eformsign Signature authentication (Access Token issuance) and Webhook verification.

### Algorithm
1. Get the current time as a 13-digit millisecond timestamp (e.g. `1700000000000`)
2. Convert that integer to a **string**, then encode as **UTF-8 bytes**
3. Sign with the **private key** (issued when the API key was created) using **SHA256withECDSA**
   - The private key is provided as a **PKCS#8 DER-encoded hex string** (Java: use `PKCS8EncodedKeySpec` — no BouncyCastle needed)
4. Convert the result to a **hex string** (`HexFormat.of().formatHex(bytes)` in Java — do NOT use `BigInteger` hex conversion as it may strip leading zeros)
5. The request must arrive within **30 seconds** of signing

> **⚠️ Do NOT use HMAC-SHA256 or any symmetric algorithm.** This is asymmetric ECDSA signing with your private key. The algorithm is SHA256withECDSA (NIST P-256 curve).

### Python
```python
# pip install ecdsa
import time
import binascii
from ecdsa import SigningKey, NIST256p

def generate_eformsign_signature(private_key_hex: str) -> tuple[str, int]:
    execution_time = int(time.time() * 1000)  # 13-digit ms timestamp — auto-generated
    message = str(execution_time).encode('utf-8')
    private_key_bytes = binascii.unhexlify(private_key_hex)
    sk = SigningKey.from_string(private_key_bytes, curve=NIST256p)
    signature_hex = binascii.hexlify(sk.sign(message)).decode('utf-8')  # SHA256withECDSA
    return signature_hex, execution_time

# Usage:
signature, execution_time = generate_eformsign_signature(PRIVATE_KEY_HEX)
headers = {
    "eformsign_signature": signature,
    "execution_time": str(execution_time),
    "Content-Type": "application/json",
}
```

> See `references/code_examples.md` for JavaScript/Java/PHP/C# implementations
