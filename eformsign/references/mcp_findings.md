# eformsign MCP Server Analysis Report

> Analysis date: 2026-05-12  
> Target: `eformsign-admin` / `eformsign-member` MCP servers

---

## 1. Full Tool List

### eformsign-admin (Admin only)

| Tool | Description | Supported actions |
|------|-------------|-------------------|
| `eformsign_auth` | Access Token management and general user API Key issuance/management | `issue_token`, `refresh_token`, `issue_member_key`, `list_member_keys`, `revoke_member_key` |
| `eformsign_document` | Document create/query/cancel/decline/resend/delete | `create`, `create_external`, `list`, `query`, `get`, **`delete`**, `cancel`, `decline`, `external_decline`, `re_request_outsider` |
| `eformsign_document_file` | Document PDF/audit trail/attachment download (returns Base64) | `download`, `download_attachments` |
| `eformsign_group` | Group query/add/update/delete | `list`, `create`, `update`, `delete` |
| `eformsign_member` | Member query/update/delete | `list`, `update`, `delete` |
| `eformsign_seal` | Stamp query/add/update/delete | `list`, `add`, `update`, `delete` |
| `eformsign_template` | Template query/detail/delete/permission update | `list`, `get`, `delete`, `update_permissions` |

### eformsign-member (General user)

| Tool | Description | Supported actions |
|------|-------------|-------------------|
| `eformsign_document` | Document create/query/cancel/decline/resend (delete not available) | `create`, `create_external`, `list`, `query`, `get`, `cancel`, `decline`, `external_decline`, `re_request_outsider` |
| `eformsign_document_file` | Document PDF/audit trail/attachment download (returns Base64) | `download`, `download_attachments` |
| `eformsign_group` | Group list query only | `list` |
| `eformsign_member` | Member list query only | `list` |
| `eformsign_seal` | Stamp list query only | `list` |
| `eformsign_template` | Templates available to current user, list query only | `list` |

---

## 2. Parameter Details

### eformsign_auth

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `action` | enum | Y | `issue_token` / `refresh_token` / `issue_member_key` / `list_member_keys` / `revoke_member_key` |
| `company_id` | string | Y for issue_member_key | Company ID |
| `member_id` | string | Y for issue_member_key | General user email |
| `key` | string | Y for revoke_member_key | API Key value to deactivate |

### eformsign_document (common to admin / member; admin adds delete)

| Parameter | Type | Required condition | Description |
|-----------|------|--------------------|-------------|
| `action` | enum | Y | Action to perform |
| `template_id` | string | Y for create, create_external | Template ID |
| `document_id` | string | Y for get, decline, external_decline, re_request_outsider | Document ID |
| `document_ids` | array | Y for delete(admin), cancel | List of document IDs |
| `company_id` | string | Y for create_external, external_decline | Company ID |
| `outside_token` | string | Y for external_decline | External recipient token |
| `type` | string | Y for list, query | `01`=in-progress, `02`=action required, `03`=completed, `04`=document management (admin only) |
| `fields` | array | — | Field values in `[{id, value}]` format |
| `recipients` | array | — | Recipient list |
| `next_steps` | array | Y for re_request_outsider | `{step_type, step_seq, recipients:[{use_mail:"true", member:{name, id}}]}` |
| `previous_steps` | string | — | Decline step (-1: previous step) |
| `is_permanent` | boolean | — | Permanent delete flag (optional for admin delete) |
| `limit` / `skip` | string | — | Pagination (default: 20 / 0) |
| `start_create_date` / `end_create_date` | integer | — | Creation date range (ms timestamp) |
| `start_update_date` / `end_update_date` | integer | — | Update date range (ms timestamp) |
| `include_fields` / `include_histories` / `include_next_status` / `include_previous_status` / `include_external_token` / `include_detail_template_info` | boolean | — | Controls which fields are included in the response |

### eformsign_document_file

| Parameter | Type | Required condition | Description |
|-----------|------|--------------------|-------------|
| `action` | enum | Y | `download` / `download_attachments` |
| `document_id` | string | Y | Document ID |
| `file_type` | string | Y for download | `document` / `audit_trail` / `document,audit_trail` |
| `file_name` | string | — | File name to save as |
| `doc_without_attachments` | boolean | — | Whether to exclude document PDF from attachment ZIP |

### eformsign_group (admin)

| Parameter | Type | Required condition | Description |
|-----------|------|--------------------|-------------|
| `action` | enum | Y | `list` / `create` / `update` / `delete` |
| `group` | object | Y for create, update | `{name, description, members:[account_id,...]}` |
| `group.description` | string | Y for update | **Empty string `""` allowed, but must always be included** |
| `group_id` | string | Y for update | Group ID |
| `group_ids` | array | Y for delete | List of group IDs to delete |
| `include_member` / `include_field` | boolean | — | Optional for list |

### eformsign_member (admin)

| Parameter | Type | Required condition | Description |
|-----------|------|--------------------|-------------|
| `action` | enum | Y | `list` / `update` / `delete` |
| `member_id` | string | Y for update, delete | Member email or account ID |
| `account` | object | Y for update | `{id, name, contact:{tel,number}, enabled, department, position, role:[]}` |
| `account.contact` | object | Server-required for update | **Empty object `{}` not allowed — must include `tel` and `number` keys** |
| `account.id` | string | — | **Use account_id string, not UUID** |

### eformsign_seal (admin)

| Parameter | Type | Required condition | Description |
|-----------|------|--------------------|-------------|
| `action` | enum | Y | `list` / `add` / `update` / `delete` |
| `stamp_id` | string | Y for update, delete | Stamp ID |
| `company_stamp` | object | Y for add, update | `{name, description, stamp:{path:dataURL}, auth:{groups:[], members:[], allow_all_members, auth_details:[]}}` |
| `company_stamp.stamp.path` | string | Y | Base64-encoded image (`data:image/png;base64,...` or `data:image/ozdpi,...` format) |

### eformsign_template (admin)

| Parameter | Type | Required condition | Description |
|-----------|------|--------------------|-------------|
| `action` | enum | Y | `list` / `get` / `delete` / `update_permissions` |
| `form_id` | string | Y for get, delete, update_permissions | Template ID |
| `is_include_config` | boolean | — | Whether to include detailed config for get |
| `use_all_members` | boolean | — | Grant usage permission to all members |
| `use` | object | — | Usage permission `{members:{add:[],delete:[]}, groups:{add:[],delete:[]}}` |
| `modify` | object | — | Edit permission `{members, groups, managers:{add:['TEMPLATE_MANAGER',...],delete:[]}}` |

---

## 3. Authentication

The MCP server handles authentication **internally and automatically**. Users (Claude) do not need to manage tokens or headers separately.

```
eformsign-admin MCP → issue_token action → Access Token issued → automatically attached to subsequent API calls
eformsign-member MCP → same flow, but operates with general user permissions
```

Internal authentication flow (performed by MCP server):
1. `eformsign_auth(action="issue_token")`: `POST https://api.eformsign.com/v2.0/api_auth/access_token`
2. Use `api_key.company.api_url` from the response as the base URL for all subsequent API calls
3. Automatically attach `oauth_token.access_token` in the `Authorization: Bearer {token}` header
4. `eformsign_auth(action="refresh_token")`: Force token refresh

External recipient document creation (`create_external`) technically requires **API Key Base64 Bearer** authentication rather than an Access Token, but the MCP abstracts this so it is handled through the same `action` parameter.

---

## 4. Error Codes and Response Structure

MCP tools receive REST API errors internally and pass them to Claude. Known error codes:

| Code | Meaning | Related tool |
|------|---------|--------------|
| `4000001` | Required input value not found | group update: description missing |
| `4000002` | Auth timeout (exceeded ±30s) | auth |
| `4000070` | Member contact field missing | member update |
| `4000115` | Domain access restriction (external recipient domain not registered) | document create_external |
| `4000125` | Admin account cannot be modified | member update |
| `4000166` | Document already cancelled | document cancel |
| `4000169` | No permission to cancel/decline document | document cancel/decline |
| `4030002` | Invalid Access Token | all |
| `4030004` | eformsign signature verification failed | auth |
| `4030039` | API key encoding error (auth error for external endpoints) | document create_external |
| `5000001~3` | Internal server error | all |

### Common error response structure
```json
{
  "code": "4000070",
  "ErrorMessage": "error description",
  "execution_time": 1700000000000
}
```

### Document status_type codes
| Code | Meaning |
|------|---------|
| `001` | Draft (temp save) |
| `002` | In progress |
| `003` | Completed |
| `011` | Decline requested |
| `021` | Declined by internal participant |
| `030` | Sent to external recipient |
| `031` | Declined by external recipient |
| `032` | Accepted by external recipient |
| `040` | Cancel requested |
| `042` | Cancelled |

---

## 5. Comparison with Reference Files — Additional Findings from MCP

### 5-1. API Key Management (not in reference files)

The `eformsign_auth` tool has **general user API Key management** actions not present in `references/api_auth.md`:

| Action | Description |
|--------|-------------|
| `issue_member_key` | Issue an API Key to a general user (company_id + member_id required) |
| `list_member_keys` | List issued API Keys (company_id optional filter) |
| `revoke_member_key` | Deactivate an API Key (key value required) |

→ Useful for operational scenarios where a separate API Key is issued for the eformsign-member server.

### 5-2. document `query` action (not classified in reference files)

`references/api_documents.md` describes document list retrieval as two methods: `GET /api/documents` (body filter) and `POST /api/list_document` (body filter).

MCP explicitly separates these:
- `list`: body filter approach (`POST /api/list_document` or `GET /api/documents` with body)
- `query`: query parameter approach

→ The distinction between the two approaches is clearer in MCP.

### 5-3. Document type 04 — confirmed admin-only

`references/api_documents.md` lists type `04`=document management, and MCP schema confirms permissions explicitly:
- **admin**: types `01`/`02`/`03`/`04` all available
- **member**: only types `01`/`02`/`03` (04 not available)

### 5-4. `re_request_outsider` — simplified recipients structure

`references/api_documents.md` shows the `re_request_outsider` body as a complex structure with both `approvers` and `recipients` arrays.

The MCP schema defines a simplified structure using only `recipients`:
```
next_steps: [{
  step_type: string,
  step_seq: string,
  recipients: [{
    use_mail: "true",   // string "true"/"false", NOT boolean
    member: { name: string, id: "email" }
  }]
}]
```
> ⚠️ The MCP schema explicitly notes that `use_mail`/`use_sms` values must be **string** `"true"`/`"false"`, not boolean.

### 5-5. Stamp (seal) — auth_details field confirmed

`references/api_org.md` shows stamp auth as `{allow_all_members, groups:[], members:[]}`, but the MCP `eformsign_seal` schema has an additional `auth_details: []` field:

```json
"auth": {
  "groups": [],
  "members": [],
  "allow_all_members": false,
  "auth_details": []   // ← not documented in api_org.md
}
```

### 5-6. Stamp image — OZD format supported

The MCP schema description additionally mentions `data:image/ozdpi,...` format.  
`references/api_org.md` only lists `data:image/png;base64,...` as an example.

### 5-7. Group update — description required (explicit in schema)

`references/api_org.md` notes this as "Known Server Behavior", but the MCP schema states it directly in the parameter description:
> "description must always be included on update"

### 5-8. Member update — contact structure (explicit in schema)

`references/api_org.md` notes this as Known Server Behavior; the MCP schema states it equally explicitly:
> "contact is server-required and must include tel/number fields"
> "Empty object {} not allowed"

### 5-9. `eformsign_document_file` — response structure (local file save approach)

Due to issues where large Base64 inline responses exceed agent context limits, the behavior was changed to **save files to local disk and return the path** (MCP server update).

Current response format:
```
Content-Type: application/pdf
Document-ID: {document_id}
File-Type: document
Size: {bytes}
Saved: C:\Users\{user}\.eformsign-mcp\downloads\{filename}_{timestamp}.pdf
```

**File naming rules:**
- If the server's `Content-Disposition` header includes a filename: saved as `{original_name}_{timestamp}.{ext}`
- If no filename in header: falls back to `{file_type}_{timestamp}.{ext}`
- Save path: `~/.eformsign-mcp/downloads/`

**Constraints:**
- `audit_trail` files are only generated for completed (`status_type=003`) documents — same constraint as the REST API
- Specifying `file_type: "document,audit_trail"` returns a ZIP
- If file save fails and the content is ≤ `maxInlineBytes` (default 5MB), falls back to Base64 inline

### 5-10. Embedding & Webhook — no MCP tools

There are no MCP tools corresponding to `references/embedding_setup.md` / `references/webhook.md`.  
→ iframe embedding and Webhook handling still require code implementation and cannot be automated via MCP.

### 5-11. `recipients` — legacy typo key `"receipients"` automatically included (confirmed in source)

**Source**: `DocumentTool.java`

When making `create` / `create_external` requests, the MCP server internally **also sends the typo key `"receipients"`**.

```java
// Legacy eformsign server compatibility — both keys sent
body.put("recipients", recipients);
body.put("receipients", recipients);  // legacy typo key
```

When writing code, use only `recipients`. The MCP automatically includes both keys.

### 5-12. `external_decline` — API Key Base64 Bearer auth (confirmed in source)

**Source**: `DocumentTool.java`

Like `create_external`, `external_decline` also uses **API Key Base64 Bearer** authentication.  
Confirmed in source code (`DocumentTool.java`); also reflected in `api_documents.md`.

```
POST {api_url}/v2.0/api/documents/{document_id}/external_decline
Authorization: Bearer {Base64(API_KEY_ID)}    ← not an Access Token
```

Calling with an Access Token returns error `4030039`.

### 5-13. MCP server architecture (confirmed in source)

**Source**: `McpServerConfig.java`, `EformsignProperties.java`

#### Transport modes

| Mode | Endpoint | Stateful | Use case |
|------|----------|----------|----------|
| SSE (HTTP) | `/mcp/admin/sse`, `/mcp/member/sse` | Stateful | Multi-client |
| Streamable HTTP | `/mcp/admin/http`, `/mcp/member/http` | Stateless | Multi-client |
| stdio | — | — | Claude Desktop, single user |

#### stdio mode — admin/member determination

Determined by whether the `EFORMSIGN_MEMBER_API_KEY` environment variable is set:
- Set → starts as member server
- Not set → starts as admin server

#### Key environment variables

**Admin (stdio)**:

| Variable | Description | Default |
|----------|-------------|---------|
| `EFORMSIGN_API_KEY` | Admin API Key | Required |
| `EFORMSIGN_AUTH_TYPE` | Auth method (`bearer` / `signature`) | `signature` |
| `EFORMSIGN_AUTH_BASE_URL` | Token issuance URL | `https://api.eformsign.com` |

**Member (stdio)**:

| Variable | Description | Default |
|----------|-------------|---------|
| `EFORMSIGN_MEMBER_API_KEY` | General user API Key | Required |
| `EFORMSIGN_SSE_BASE_URL` | SSE server URL | `http://localhost:8085` |

#### Supported clients (as of 2026-05)

Cursor, VS Code, Codex, Claude Code, Claude Desktop, Gemini CLI, Antigravity, Windsurf, Zed

#### Supported databases (Flyway migration)

H2 / MySQL / PostgreSQL / SQL Server

#### Token refresh strategy

- Proactive refresh **300 seconds before** expiry
- On 401 response: refresh then **retry once**
- On `4030002`: full re-issuance (including Refresh Token invalidation)

### 5-14. Admin vs member permission comparison

| Feature | admin | member |
|---------|-------|--------|
| Document delete | ✅ | ❌ |
| Document type 04 query | ✅ | ❌ |
| Group CRUD | ✅ | list only |
| Member update/delete | ✅ | list only |
| Stamp CRUD | ✅ | list only |
| Template delete/permission update | ✅ | ❌ |
| API Key issuance/management | ✅ | ❌ |

---

## Summary: Key Findings

1. **API Key management**: `eformsign_auth` tool has `issue_member_key` / `list_member_keys` / `revoke_member_key` actions — operational features not documented in the reference files.

2. **`query` vs `list` distinction**: Query parameter approach and body filter approach are explicitly separated in MCP.

3. **type 04 confirmed admin-only**: Document type 04 (document management) confirmed to work only with admin, per MCP schema.

4. **`re_request_outsider` recipients — string boolean**: `use_mail`/`use_sms` must be passed as string `"true"`, not boolean.

5. **Stamp `auth_details` field**: Field exists in MCP schema but not in API documentation.

6. **Embedding & Webhook not supported via MCP**: Remain code implementation territory.

7. **Known Server Behavior match**: MCP schema reflects the same server behavior discrepancies recorded in `references/api_org.md` (group description required, member contact required), confirming reliability.

8. **File download — local save first, Base64 fallback**: `eformsign_document_file` defaults to saving to `~/.eformsign-mcp/downloads/` and returning the path. Falls back to Base64 inline (≤5MB) only if save fails. When receiving Base64, strip `</tool_response>` tag before decoding.

9. **`receipients` typo key auto-included**: MCP server sends legacy typo key `"receipients"` alongside `recipients` (confirmed in source). Use only `recipients` when writing code.

10. **`external_decline` — API Key Base64 Bearer auth**: Same as `create_external` — requires API Key Base64 Bearer auth, not Access Token (confirmed in source). Was missing from `api_documents.md`.

11. **MCP server transport modes**: Three modes — stdio (Claude Desktop, single user), SSE, Streamable HTTP. In stdio mode, admin/member role is determined automatically by presence of `EFORMSIGN_MEMBER_API_KEY`. Supports 9 clients (Cursor, VS Code, Codex, Claude Code, Claude Desktop, Gemini CLI, Antigravity, Windsurf, Zed).
