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

## Member API Key Management (MCP Server Only)

> ⚠️ **These operations are available only through the eformsign MCP server** (`eformsign_auth` tool).
> There are no corresponding REST API endpoints — they cannot be called directly via HTTP.

The MCP server's `eformsign_auth` tool provides the following additional actions for managing
API keys on behalf of individual company members:

| Action | Description | Required Parameters |
|--------|-------------|---------------------|
| `issue_member_key` | Issue an API key for a specific member | `company_id`, `member_id` |
| `list_member_keys` | List issued API keys | `company_id` (optional filter) |
| `revoke_member_key` | Deactivate an API key | `key` (the API key value) |

These are used in operational scenarios where the eformsign-member MCP server needs a separate
API key issued per end-user.

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

> See `references/code_examples.md` for language-specific implementations
