---
name: eformsign
description: >
  Expert reference for the eformsign electronic document service.
  Use when: any question about eformsign API (documents, templates, members, groups),
  debugging or troubleshooting eformsign integrations, understanding eformsign API
  behavior or error codes, writing eformsign integration code, embedding eformsign
  document signing via iframe, handling Webhook events, or implementing eformsign
  authentication (Bearer / Basic / eformsign Signature). Includes known server quirks
  and undocumented fields. Supported languages: Python, JavaScript/Node.js, Java, PHP, C#.
---

# eformsign Development Skill

eformsign is an electronic document SaaS platform. There are **4 integration methods**:
- **Embedding**: Embed eformsign features directly into your web service via iframe
- **Open API**: Programmatically control documents, templates, and organizations via REST API
- **Webhook**: Receive real-time document state change events to your system via HTTP POST
- **MCP**: Use eformsign via MCP tools (eformsign-admin / eformsign-member server) in AI agent workflows

## Reference Files

Read the appropriate reference file based on your task:

| Task | File |
|------|------|
| API authentication, signature generation, token issuance/refresh | `references/api_auth.md` |
| Document create/query/download/delete/bulk API | `references/api_documents.md` |
| Template, member, group, seal management API | `references/api_org.md` |
| Embedding: script loading, SDK objects (EformSignDocument/Template) | `references/embedding_setup.md` |
| Embedding: document_option, user/mode/layout/prefill configuration | `references/embedding_config.md` |
| Embedding: advanced options, callbacks, full examples | `references/embedding_advanced.md` |
| Webhook setup, verification, and event handling | `references/webhook.md` |
| Language-specific code examples (Python/JS/Java/PHP/C#) | `references/code_examples.md` |
| Known SDK bugs, undocumented fields, and official doc discrepancies | `references/sdk_findings.md` |
| MCP tool list, parameters, behaviors, and differences from REST API | `references/mcp_findings.md` |

## Multi-File Scenarios

Some tasks require reading multiple reference files. Read all listed files before answering:

- **External user signing flow** (Webhook → Embedding): Read `references/webhook.md` to extract `outside_token` from the `doc_request_participant` event, then read `references/embedding_config.md` for the `auth_id` embedding configuration.

- **Full API integration** (auth + document/org operations): Read `references/api_auth.md` first to understand token issuance, then read the relevant API file (`api_documents.md` or `api_org.md`) for the specific endpoint.

- **Embedding setup + configuration**: Read `references/embedding_setup.md` for script loading and SDK objects, then `references/embedding_config.md` for `document_option` details. Add `references/embedding_advanced.md` if callbacks or advanced options are needed.

- **Webhook + PDF download**: Read `references/webhook.md` for the `ready_document_pdf` event, then `references/api_documents.md` for the download API.

- **Embedding + PDF download after completion**: Read `references/embedding_advanced.md` for the `success_callback` (to obtain `document_id`), then `references/api_documents.md` for the PDF download API.

- **Embedding with SDK bug workarounds**: Always read `references/sdk_findings.md` alongside `references/embedding_setup.md` and/or `references/embedding_config.md` when implementing embedding — it contains undocumented required fields (`auth_id`) and critical bug fixes (global constant collision) not present in official docs.

- **Template lookup then embed**: Read `references/api_org.md` to retrieve the template list and obtain a `template_id`, then `references/embedding_config.md` to configure `mode.template_id` for embedding.

- **Webhook signature verification**: Read `references/webhook.md` for the verification flow and code examples, then `references/api_auth.md` if you need background on the SHA256withECDSA algorithm.

- **Internal user processing a received document (embedding)**: Read `references/api_auth.md` for token issuance, then `references/embedding_config.md` for the `user.internal_token` field (required when a company member signs/approves a document they received — omitted from some official docs).

- **Advanced prefill (batch preview or dataset binding)**: Read `references/embedding_config.md` for basic `prefill` configuration, then `references/embedding_advanced.md` for the `prefills` array (sequential batch preview) and `form_parameters` (external dataset binding).

- **MCP tool usage (admin)**: Read `references/mcp_findings.md` for the full tool list, parameter schemas, and known behavioral differences from the REST API (e.g. `use_mail` as string, `auth_details` field, file download to local path).

- **MCP tool usage (member)**: Read `references/mcp_findings.md` — focus on the member tool table (Section 1) and the admin vs member permission comparison (Section 5-14). Member tools exclude `delete`, type `04` queries, and all org write operations.

## Key Concepts

### API Basics
- **Base URL**: Use the `api_url` value from the Access Token response — there is no fixed base URL
- **Auth header**: `Authorization: Bearer {access_token}` required on every API call
- **Access Token TTL**: 3600 seconds (1 hour); renew with `refresh_token`
- **API version**: v2.0 (contact support for v1.0)

### eformsign Signature
- Algorithm: SHA256withECDSA (elliptic curve asymmetric encryption)
- Sign: current time as a 13-digit millisecond timestamp, encoded as UTF-8 bytes, signed with the private key
- Validity: request must arrive within **30 seconds** of signing
- Header: `eformsign_signature: {signature as hex string}`

### Authentication Types
| Type | Header |
|------|--------|
| Bearer Token | `Authorization: Bearer {pre-configured token}` |
| Basic Authentication | `Authorization: Basic {Base64(ID:Password)}` |
| eformsign Signature | `eformsign_signature: {SHA256withECDSA signature hex}` |

### Error Codes
| Code | Meaning |
|------|---------|
| 200 | Success |
| 4000002 | Auth time expired (exceeded 30s) |
| 4030002 | Invalid Access Token |
| 4030004 | Signature verification failed |
| 5000001–3 | Server error |

### Document Status Codes
| Status | Code | Meaning |
|--------|------|---------|
| doc_tempsave | 001 | Draft (temp save) |
| doc_create | 002 | Document in progress |
| doc_complete | 003 | Document completed |
| doc_request_outsider | 030 | Sent to external recipient |
| doc_accept_outsider | 032 | External recipient accepted |
| doc_deleted | — | Document deleted |
| doc_reject_participant | — | Rejected by a participant |

## Implementation Workflows

### API Integration
1. Create an **API key** in the admin console (Connect > API/Webhook > API Key Management)
2. **Issue an Access Token** using the API key → save `api_url`, `access_token`, `refresh_token`
3. **Call APIs** using `api_url` + endpoint path
4. **Refresh** with the Refresh Token when the Access Token expires

> See `references/api_auth.md`, `references/api_documents.md`, `references/api_org.md` for full endpoint and request/response schemas

### Embedding
1. Load 3 scripts in HTML (jQuery, efs_embedded_v2.js, efs_embedded_form.js)
2. Build the `document_option` object (company, mode, user, layout, prefill sections)
3. Call `eformsign.document()` then `eformsign.open()`

> See `references/embedding_setup.md`, `references/embedding_config.md`, `references/embedding_advanced.md` for detailed options and callback setup

### Webhook Handling
1. Register a Webhook in the admin console (endpoint URL, verification type)
2. Receive HTTP POST → check `event_type` (`document` or `ready_document_pdf`)
3. (Optional) Verify request authenticity using the eformsign Signature header
4. Parse `document` or `ready_document_pdf` object and run business logic

> See `references/webhook.md` for event structure, verification code, and server examples

### MCP Integration
1. Run the eformsign MCP server (`eformsign-admin` or `eformsign-member`)
2. Connect an AI agent (Claude, etc.) via SSE or stdio transport
3. Use MCP tools — authentication is handled internally by the server
4. Admin server: full CRUD on documents, templates, members, groups, seals + API key management
5. Member server: document create/query/download + read-only access to org resources

> See `references/mcp_findings.md` for tool list, parameter schemas, and behavioral notes
