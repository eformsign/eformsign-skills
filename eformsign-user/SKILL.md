---
name: eformsign-user
description: >
  Expert reference for end-users integrating the eformsign electronic document service.
  Use when: any question about eformsign document API (create, query, download),
  debugging or troubleshooting eformsign embedding or Webhook issues, understanding
  eformsign API behavior or error codes, embedding eformsign document signing/viewing
  into a webpage, handling Webhook events for document status changes, or implementing
  eformsign authentication. Covers known server quirks and undocumented SDK fields.
  Supported languages: Python, JavaScript/Node.js, Java, PHP, C#.
---

# eformsign User Integration Skill

eformsign is an electronic document SaaS platform. This skill covers the integration methods
available to general application users (not admin-level organization management).

## Reference Files

Read the appropriate reference file based on your task:

| Task | File |
|------|------|
| API authentication, token issuance/refresh, signature generation | `references/api_auth.md` |
| Document create, query, download, delete, cancel, reject | `references/api_documents.md` |
| Embedding: script loading, SDK objects (EformSignDocument) | `references/embedding_setup.md` |
| Embedding: document_option, user/mode/layout/prefill configuration | `references/embedding_config.md` |
| Embedding: advanced options, callbacks, full examples | `references/embedding_advanced.md` |
| Webhook setup, verification, and event handling | `references/webhook.md` |
| Language-specific code examples (Python/JS/Java/PHP/C#) | `references/code_examples.md` |
| Known SDK bugs, undocumented fields, and official doc discrepancies | `references/sdk_findings.md` |
| MCP member tool parameters, file download behavior, permission limits | `references/mcp_findings.md` |

## Multi-File Scenarios

Some tasks require reading multiple reference files. Read all listed files before answering:

- **External user signing flow** (Webhook → Embedding): Read `references/webhook.md` to extract `outside_token` from the `doc_request_participant` event, then read `references/embedding_config.md` for the `auth_id` embedding configuration.

- **Full API integration** (auth + document operations): Read `references/api_auth.md` first to understand token issuance, then read `references/api_documents.md` for the specific endpoint.

- **Embedding setup + configuration**: Read `references/embedding_setup.md` for script loading and SDK objects, then `references/embedding_config.md` for `document_option` details. Add `references/embedding_advanced.md` if callbacks or advanced options are needed.

- **Webhook + PDF download**: Read `references/webhook.md` for the `ready_document_pdf` event, then `references/api_documents.md` for the download API.

- **Embedding + PDF download after completion**: Read `references/embedding_advanced.md` for the `success_callback` (to obtain `document_id`), then `references/api_documents.md` for the PDF download API.

- **Embedding with SDK bug workarounds**: Always read `references/sdk_findings.md` alongside `references/embedding_setup.md` and/or `references/embedding_config.md` when implementing embedding — it contains undocumented required fields (`auth_id`) and critical bug fixes (global constant collision) not present in official docs.

- **Webhook signature verification**: Read `references/webhook.md` for the verification flow and code examples, then `references/api_auth.md` if you need background on the SHA256withECDSA algorithm.

- **Internal user processing a received document (embedding)**: Read `references/api_auth.md` for token issuance, then `references/embedding_config.md` for the `user.internal_token` field (required when a company member signs/approves a document they received).

- **Advanced prefill (batch preview or dataset binding)**: Read `references/embedding_config.md` for basic `prefill` configuration, then `references/embedding_advanced.md` for the `prefills` array and `form_parameters`.

- **MCP member tool usage**: Read `references/mcp_findings.md` for the member tool list (Section 1), parameter schemas (Section 2), and permission limits vs admin (Section 5-14). Note: member tools exclude document `delete`, type `04` queries, and all org write operations. File downloads save to `~/.eformsign-mcp/downloads/` locally.

## Key Concepts

### API Basics
- **Base URL**: Use the `api_url` value from the Access Token response — there is no fixed base URL
- **Auth header**: `Authorization: Bearer {access_token}` required on every API call
- **Access Token TTL**: 3600 seconds (1 hour); renew with `refresh_token`

### eformsign Signature
- Algorithm: SHA256withECDSA (elliptic curve asymmetric encryption)
- Sign: current time as a 13-digit millisecond timestamp, encoded as UTF-8 bytes, signed with the private key
- Validity: request must arrive within **30 seconds** of signing
- Header: `eformsign_signature: {signature as hex string}`

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

> See `references/api_auth.md` and `references/api_documents.md` for full endpoint and request/response schemas

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
