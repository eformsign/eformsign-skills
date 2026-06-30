# eformsign API — Documents

## Known Server Behavior (Document APIs)

> Confirmed discrepancies between the API spec and actual server behavior:

| Endpoint | Issue |
|----------|-------|
| `GET /api/documents` | Spec: body is optional. **Actual: returns 400 without body. Always include body.** However, the official spec notes that some HTTP clients/proxies may not support or may silently drop GET request bodies — in such environments, use `POST /api/list_document` instead for reliable behavior. |
| `POST /api/list_document` | Swagger spec says `/api/list_documents` (plural), but **actual server uses `/api/list_document` (singular)**. Plural path returns 404. |
| `GET /api/documents/{id}/download_files` | Spec: no status restriction. **Actual: only works for completed (status_type=003) documents. Returns 400 for in-progress or draft.** |
| `DELETE /api/documents` | Spec: `comment` is optional. **Actual: `comment` is required. Omitting it causes an error. Send `""` if no reason needed.** |
| `GET /api/documents` / `POST /api/list_document` | Spec: `limit` is optional. **Actual: omitting `limit` causes the API to return an empty list even when documents exist. Always specify `limit` (e.g., `"20"`).** |

---

## Document API

Common headers for all document APIs:
```
Authorization: Bearer {access_token}
Content-Type: application/json
```

### Create Document (member) ✅ Swagger Official
```
POST {api_url}/v2.0/api/documents?template_id={template_id}
```

**Body:**
```json
{
  "document": {
    "document_name": "Document Name",
    "comment": "Message to recipients",
    "fields": [
      { "id": "FieldName", "value": "Value" }
    ],
    "parameters": [
      { "id": "ParameterID", "value": "Value" }
    ],
    "select_group_name": "GroupName",
    "recipients": [
      {
        "step_type": "05",
        "use_mail": true,
        "use_sms": false,
        "is_noti_ignore": false,
        "member": {
          "name": "John Doe",
          "id": "johndoe@example.com",
          "sms": {
            "country_code": "+82",
            "phone_number": "1012345678"
          }
        },
        "group": {
          "id": "group_id"
        },
        "auth": {
          "password": "1234",
          "password_hint": "Last 4 digits of your phone number",
          "valid": { "day": 7, "hour": 0 }
        }
      }
    ],
    "notification": [
      {
        "name": "Notifier Name",
        "email": "notify@example.com",
        "sms": { "country_code": "+82", "phone_number": "1012345678" }
      }
    ]
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| document.document_name | string | N | Document name |
| document.comment | string | N | Message to recipients |
| document.fields | array | N | Fields to pre-fill |
| document.parameters | array | N | Template parameters |
| document.select_group_name | string | N | Assign to group |
| document.recipients | array | N | Recipient list |
| recipients[].step_type | string | Y | Step type code (see table below) |
| recipients[].use_mail | boolean | N | Send email notification |
| recipients[].use_sms | boolean | N | Send SMS notification |
| recipients[].is_noti_ignore | boolean | N | Suppress notification (default: false) |
| recipients[].member | object | N | Member info |
| recipients[].group | object | N | Group info |
| recipients[].auth | object | N | Authentication settings |
| document.notification | array | N | Read-notification recipients |

**Response:**
```json
{
  "template_id": "template_id",
  "document": {
    "id": "document_id",
    "document_name": "Document Name"
  },
  "recipients": [
    {
      "member": {
        "name": "John Doe",
        "id": "johndoe@example.com",
        "sms": { "country_code": "+82", "phone_number": "1012345678" },
        "token_id": "token_id"
      }
    }
  ]
}
```

---

### Create Document (external recipient) ✅ Swagger Official
```
POST {api_url}/v2.0/api/documents/external?company_id={company_id}&template_id={template_id}
```

> ⚠️ **Auth method differs from other APIs:** Requires **API Key Base64 Bearer** authentication, NOT a regular Access Token.
> - Header: `Authorization: Bearer {Base64(API_KEY_ID)}`
> - Using an Access Token returns error **4030039** (apiKey encoding error)
> - Error **4000115**: domain access restriction — configure allowed external recipient domains in Admin Console > Connect > API/Webhook

> ⚠️ **`recipients` is required** — `send_external_pdf` alone is not sufficient. The server requires the `recipients` (or legacy typo key `receipients`) array. Include both keys to be safe with legacy endpoints.

Same body structure as member method, with `recipients` and `send_external_pdf` added inside `document`:
```json
{
  "document": {
    "document_name": "Document Name",
    "fields": [{ "id": "FieldName", "value": "Value" }],
    "recipients": [
      {
        "step_type": "03",
        "name": "Hong Gildong",
        "email": "recipient@example.com",
        "use_mail": true
      }
    ],
    "receipients": [
      {
        "step_type": "03",
        "name": "Hong Gildong",
        "email": "recipient@example.com",
        "use_mail": true
      }
    ],
    "send_external_pdf": {
      "email": "recipient@example.com",
      "sms": { "country_code": "+82", "phone_number": "1012345678" },
      "auth": {
        "password": "1234",
        "password_hint": "Last 4 digits of phone"
      }
    }
  }
}
```

**`step_type` codes for external recipients:**
| Value | Meaning | Required fields |
|-------|---------|-----------------|
| `03` | External recipient (legacy) | `name`, `email` (or `sms` per template notification config) |
| `05` | Participant (new-style) | `member.name`, `member.id` |

> ⚠️ `use_mail: true` or `use_sms: true` must be set on each recipient, otherwise error **4000001** is returned.

---

### Bulk Create Documents 📘 Dev Guide
```
POST {api_url}/v2.0/api/documents/bulk?template_id={template_id}
```

**Body:**
```json
{
  "documents": [
    {
      "document_name": "Document 1",
      "fields": [{ "id": "FieldName", "value": "Value" }],
      "recipients": []
    }
  ]
}
```

---

### List Documents ✅ Swagger Official
```
GET  {api_url}/v2.0/api/documents          # body filter method
POST {api_url}/v2.0/api/list_document      # body filter method (⚠️ singular — Swagger says /list_documents but returns 404)
```

> ⚠️ Body is required for `GET /api/documents` — server returns 400 without it despite spec saying optional.

> **list vs query**: The two endpoints above use a **body filter** approach. Some integrations (e.g., MCP server) expose a separate `query` action that uses **query parameters** instead of a request body. Both retrieve the same document data — the difference is only in how filters are passed.

> **type `04` (manage) is admin-only**: Regular members can only use types `01`/`02`/`03`. Using type `04` without admin privileges returns an error.

**Query Parameters (all optional):**
| Parameter | Type | Description |
|-----------|------|-------------|
| include_fields | boolean | Include field data |
| include_histories | boolean | Include document history |
| include_previous_status | boolean | Include previous step info |
| include_next_status | boolean | Include next step info |
| include_external_token | boolean | Include participant tokens |

**Body (required in practice):**
```json
{
  "type": "01",
  "template_ids": ["template_id_1", "template_id_2"],
  "title_and_content": "search keyword",
  "title": "title keyword",
  "content": "content keyword",
  "start_create_date": 1700000000000,
  "end_create_date": 1700000000000,
  "start_update_date": 1700000000000,
  "end_update_date": 1700000000000,
  "limit": "20",
  "skip": "0"
}
```

| Field | Description |
|-------|-------------|
| type | Document type filter: `01` in-progress, `02` action required, `03` completed, `04` manage |
| template_ids | Filter by template ID list |
| title_and_content | Search title and content together |
| start/end_create_date | Creation date range (ms timestamp) |
| start/end_update_date | Update date range (ms timestamp) |
| limit | Items per page (default: 20) |
| skip | Offset (default: 0) |

**Response:**
```json
{
  "documents": [
    {
      "id": "document_id",
      "template": { "id": "template_id", "name": "Template Name" },
      "document_name": "Document Name",
      "document_number": "DOC-001",
      "creator": { "recipient_type": "string", "id": "user@example.com", "name": "John Doe" },
      "created_date": 1700000000000,
      "updated_date": 1700000000000,
      "current_status": {
        "status_type": "003",
        "step_type": "string",
        "step_index": "string",
        "step_name": "string",
        "expired_date": 0,
        "_expired": false
      },
      "fields": [{ "id": "string", "value": "string", "type": "string" }]
    }
  ],
  "total_rows": 100,
  "limit": 20,
  "skip": 0
}
```

---

### Get Document ✅ Swagger Official
```
GET {api_url}/v2.0/api/documents/{document_id}
```

**Query Parameters (all optional):**
| Parameter | Type | Description |
|-----------|------|-------------|
| include_fields | boolean | Include field data |
| include_histories | boolean | Include history |
| include_previous_status | boolean | Include previous step |
| include_next_status | boolean | Include next step |
| include_external_token | boolean | Include participant tokens |
| include_detail_template_info | boolean | Include detailed template config |

**Response:**
```json
{
  "id": "document_id",
  "document_number": "DOC-001",
  "template": { "id": "template_id", "name": "Template Name" },
  "document_name": "Document Name",
  "creator": { "recipient_type": "string", "id": "user@example.com", "name": "John Doe" },
  "created_date": 1700000000000,
  "updated_date": 1700000000000,
  "current_status": {},
  "fields": [],
  "recipients": [
    {
      "name": "John Doe",
      "id": "user@example.com",
      "sms": { "country_code": "+82", "phone_number": "1012345678" },
      "token_id": "string",
      "complete_token_id": "string"
    }
  ],
  "next_status": [],
  "previous_status": [],
  "histories": [],
  "detail_template_info": [],
  "record_key": "string"
}
```

---

### Download Document Files ✅ Swagger Official
```
GET {api_url}/v2.0/api/documents/{document_id}/download_files
```

> ⚠️ Spec has no status restriction, but the actual server **only works for completed (status_type=003) documents**. Returns 400 for in-progress or draft documents. `audit_trail` is only generated for completed documents.

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| file_type | string | Y | `document` \| `audit_trail` \| `document,audit_trail` |
| file_name | string | N | Output file name |

**Response:** `application/pdf` or `application/zip` binary stream

---

### Download Attachment Files ✅ Swagger Official
```
GET {api_url}/v2.0/api/documents/{document_id}/download_attach_files
```

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| doc_without_attachments | boolean | N | Exclude document PDF, attachments only (default: false) |

**Response:** `application/zip` binary stream

---

### Delete Documents ✅ Swagger Official
```
DELETE {api_url}/v2.0/api/documents
```

> ⚠️ **`comment` is required in the body** — the server treats `comment` as a required property alongside `document_ids`. Omitting it causes an error. Send an empty string `""` if no reason is needed.

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| is_permanent | boolean | N | Permanently delete (default: false) |

**Body:**
```json
{
  "document_ids": ["document_id_1", "document_id_2"],
  "comment": "Reason for deletion"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| document_ids | array(string) | Y | Document IDs to delete |
| comment | string | **Y** | Deletion reason. Send `""` if no reason needed — omitting the field causes an error |

**Response:**
```json
{
  "result": {
    "success_result": ["document_id_1"],
    "fail_result": [
      { "document_id": "string", "code": "string", "message": "string" }
    ]
  }
}
```

---

### Cancel Documents 📘 Dev Guide
```
POST {api_url}/v2.0/api/documents/cancel
```

**Body:**
```json
{
  "input": {
    "document_ids": ["document_id_1", "document_id_2"],
    "comment": "Reason for cancellation"
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| input.document_ids | array(string) | Y | Document IDs to cancel |
| input.comment | string | N | Cancellation reason |

**Response:**
```json
{
  "result": {
    "success_result": "document_id_1",
    "fail_result": [
      { "document_id": "string", "code": "4000169", "message": "You are not authorized to revoke the document." }
    ]
  }
}
```

---

### Decline Document (internal) 📘 Dev Guide
```
POST {api_url}/v2.0/api/documents/{document_id}/decline
```

> ⚠️ Path uses `/api/documents/` (plural). Using `/api/document/` (singular) returns 404.

**Body:**
```json
{
  "previous_steps": "-1",
  "comment": "Reason for decline"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| previous_steps | string | N | Step to return to (`-1` = previous step) |
| comment | string | N | Decline reason |

**Response:**
```json
{
  "document_title": "Contract_JohnDoe",
  "document_id": "document_id"
}
```

---

### Decline Document (external) 📘 Dev Guide
```
POST {api_url}/v2.0/api/documents/{document_id}/external_decline
```

> ⚠️ Path uses `/api/documents/` (plural). Using `/api/document/` (singular) returns 404.
> ⚠️ **Auth method same as `create_external`**: Requires **API Key Base64 Bearer** authentication. Using a regular Access Token returns error **4030039**.

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| company_id | string | Y | Company ID |
| outside_token | string | Y | External recipient token |

**Body:**
```json
{ "comment": "Reason for decline" }
```

---

### Re-send to External Recipient ✅ Swagger Official
```
POST {api_url}/v2.0/api/documents/{document_id}/re_request_outsider
```

**Body:**
```json
{
  "input": {
    "next_steps": [
      {
        "step_type": "05",
        "step_seq": "string",
        "approvers": [
          {
            "seq": "string",
            "user_id": "user@example.com",
            "user_name": "John Doe",
            "code": "+82",
            "number": "1012345678",
            "auth_password": "string",
            "auth_hint": "string",
            "auth_valid_time": "168",
            "approval_line_name": "string",
            "use_mobile_auth": "false",
            "use_mobile_auth_view": "false",
            "unselected_sections": ["string"]
          }
        ],
        "recipients": [
          {
            "step_type": "string",
            "step_seq": "string",
            "use_mail": "true",   // ⚠️ string "true"/"false", NOT boolean
            "use_sms": "false",   // ⚠️ string "true"/"false", NOT boolean
            "member": {
              "name": "John Doe",
              "id": "user@example.com",
              "sms": { "country_code": "+82", "phone_number": "1012345678" }
            },
            "business_num": "string",
            "group": { "id": "string" },
            "auth": {
              "password": "string",
              "password_hint": "string",
              "valid": { "day": 7, "hour": 0 }
            },
            "hidden_sections": ["string"]
          }
        ],
        "comment": "string"
      }
    ]
  }
}
```
