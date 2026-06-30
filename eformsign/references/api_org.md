# eformsign API — Templates, Members, Groups & Stamps

## Known Server Behavior (Org APIs)

> Confirmed discrepancies between the API spec and actual server behavior:

| Endpoint | Issue |
|----------|-------|
| `PATCH /api/members/{id}` | `account.contact` is required (4000070 if missing). Empty object `{}` not allowed — must include `tel`/`number` keys. `account.id` must be account_id string, not UUID. Admin accounts cannot be modified (4000125). |
| `PATCH /api/groups/{id}` | `group.description` is required on actual server — returns 4000001 if omitted. Empty string `""` is acceptable. |

---

## Template API

### List Templates ✅ Swagger Official
```
GET {api_url}/v2.0/api/forms
```

**Response:**
```json
{
  "total_rows": 10,
  "templates": [
    {
      "form_id": "string",
      "name": "Template Name",
      "version": "string",
      "abbreviation": "string",
      "enabled": true,
      "category": "string",
      "keyword": "string",
      "desc": "description",
      "favorite": false,
      "start_write_date": 1700000000000,
      "end_write_date": 1700000000000,
      "unlimited": true,
      "create_id": "user@example.com",
      "create_name": "John Doe",
      "create_date": 1700000000000,
      "update_id": "user@example.com",
      "update_name": "John Doe",
      "update_date": 1700000000000,
      "owner_id": "user@example.com",
      "owner_name": "John Doe",
      "use_document_numbering": false,
      "document_numbering_rule_id": "string",
      "use_ai": false,
      "is_release": true,
      "is_update": false,
      "is_sample": false,
      "form_modify_auth": true,
      "file": {
        "form_image_id": "string",
        "form_files": [
          {
            "type": "string",
            "ozr_id": "string",
            "ext": "string",
            "alias": "string",
            "file_id": "string"
          }
        ]
      }
    }
  ]
}
```

---

### Get Template ✅ Swagger Official
```
GET {api_url}/v2.0/api/forms/{form_id}
```

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| is_include_config | boolean | N | Include configuration details |

**Response:** Same fields as List Templates single item, plus:
```json
{
  "title_change": true,
  "quick_processing": false,
  "form_doc_retention_period": 0,
  "config": {
    "parameters": {},
    "display_settings": [],
    "step_settings": [],
    "input_form_parameters": [],
    "input_component_parameters": [],
    "external_access": {},
    "notification": {}
  }
}
```

---

### Update Template Permissions 📘 Dev Guide
```
PATCH {api_url}/v2.0/api/forms/{form_id}/permissions
```

**Body:**
```json
{
  "use_all_members": false,
  "use": {
    "members": { "add": ["user1@example.com"], "delete": ["user2@example.com"] },
    "groups": { "add": ["group1"], "delete": ["group2"] }
  },
  "modify": {
    "members": { "add": ["string"], "delete": ["string"] },
    "groups": { "add": ["string"], "delete": ["string"] },
    "managers": {
      "add": ["TEMPLATE_MANAGER", "DOCUMENT_MANAGER"],
      "delete": ["COMPANY_MANAGER"]
    }
  }
}
```

| Field | Description |
|-------|-------------|
| use_all_members | Grant usage permission to all members |
| use.members.add/delete | Add/remove member usage permissions |
| use.groups.add/delete | Add/remove group usage permissions |
| modify.managers.add/delete | Manager roles: `TEMPLATE_MANAGER`, `DOCUMENT_MANAGER`, `COMPANY_MANAGER` |

---

### Delete Template ✅ Swagger Official
```
DELETE {api_url}/v2.0/api/forms/{form_id}
```

---

## Member API

### List Members ✅ Swagger Official
```
GET {api_url}/v2.0/api/members
```

**Query Parameters (all optional):**
| Parameter | Type | Description |
|-----------|------|-------------|
| member_all | boolean | Return all members |
| include_field | boolean | Include custom field format info |
| include_delete | boolean | Include deleted members |
| eb_name_search | string | Search by name or account ID |

**Response:**
```json
{
  "members": [
    {
      "id": "user@example.com",
      "account_id": "user@example.com",
      "name": "John Doe",
      "department": "Engineering",
      "position": "Manager",
      "enabled": true,
      "role": ["admin", "company_manager", "template_manager", "document_manager", "member"],
      "group": ["GroupName"],
      "contact": { "country_id": "+82", "number": "1012345678", "tel": "0234567890" }
    }
  ]
}
```

---

### Update Member ✅ Swagger Official
```
PATCH {api_url}/v2.0/api/members/{member_id}
```

> ⚠️ **Known server behavior (tested)**
> 1. **`account.contact` is required** — returns 4000070 if missing (spec says optional)
> 2. **`account.contact` empty object `{}` not allowed** — must include `tel` and `number` keys (empty strings `""` are acceptable)
> 3. **`account.id` must be account_id string** — use login ID (e.g. `user@example.com`), not internal UUID
> 4. **Admin accounts cannot be modified** — returns 4000125 if `role` contains `admin`

**Body:**
```json
{
  "account": {
    "id": "user@example.com",
    "name": "John Doe",
    "enabled": true,
    "contact": { "tel": "0234567890", "number": "1012345678" },
    "department": "Engineering",
    "position": "Manager",
    "role": ["member", "company_manager"]
  }
}
```

| Field | Type | Spec Required | Server Required | Description |
|-------|------|--------------|-----------------|-------------|
| account.id | string | N | **Effectively Y** | account_id string (login ID). UUID not accepted |
| account.name | string | N | Effectively Y | Member name |
| account.enabled | boolean | N | N | Activation status |
| account.contact | object | N | **Y** | Missing returns 4000070. Empty `{}` not allowed; must include `tel`/`number` |
| account.contact.tel | string | N | **Y** | Office phone. Empty string `""` allowed |
| account.contact.number | string | N | **Y** | Mobile phone. Empty string `""` allowed |
| account.department | string | N | N | Department |
| account.position | string | N | N | Position/title |
| account.role | array(string) | N | N | Role list |

---

### Delete Member ✅ Swagger Official
```
DELETE {api_url}/v2.0/api/members/{member_id}
```

---

## Group API

### List Groups 📘 Dev Guide
```
GET {api_url}/v2.0/api/groups
```

**Query Parameters (all optional):**
| Parameter | Type | Description |
|-----------|------|-------------|
| include_member | boolean | Include member details |
| include_field | boolean | Include custom field info |

---

### Create Group 📘 Dev Guide
```
POST {api_url}/v2.0/api/groups
```

**Body:**
```json
{
  "group": {
    "name": "Group Name",
    "description": "Description",
    "members": ["user1@example.com", "user2@example.com"]
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| group.name | string | Y | Group name |
| group.description | string | N | Group description |
| group.members | array(string) | N | Member email list |

**Response:**
```json
{
  "group": { "id": "group_id", "name": "Group Name" }
}
```

---

### Update Group 📘 Dev Guide
```
PATCH {api_url}/v2.0/api/groups/{group_id}
```

> ⚠️ `group.description` is required on the actual server — returns 4000001 "Required input value not found" if omitted. Empty string `""` is acceptable.

**Body:**
```json
{
  "group": {
    "name": "Group Name",
    "description": "Description",
    "members": ["user1@example.com", "user2@example.com"]
  }
}
```

| Field | Type | Spec Required | Server Required | Description |
|-------|------|--------------|-----------------|-------------|
| group.name | string | Y | Y | Group name |
| group.description | string | N | **Y** | Group description. Empty string `""` allowed |
| group.members | array | N | N | Member account_id list |

---

### Delete Groups 📘 Dev Guide
```
DELETE {api_url}/v2.0/api/groups
```

**Body:**
```json
{
  "group_ids": ["group_id_1", "group_id_2"]
}
```

---

## Company Stamp API

### List Stamps 📘 Dev Guide
```
GET {api_url}/v2.0/api/company_stamp
```

**Response:**
```json
{
  "total_rows": 2,
  "company_stamps": [
    {
      "id": "string",
      "name": "Company Stamp",
      "description": "description",
      "stamp": {
        "type": "image",
        "file": "filename.png",
        "path": "data:image/png;base64,..."
      },
      "auth": {
        "allow_all_members": false,
        "groups": [{ "_id": "string", "name": "Group1" }],
        "members": [{ "_id": "user@example.com", "account_id": "user@example.com" }]
      }
    }
  ]
}
```

---

### Add Stamp 📘 Dev Guide
```
POST {api_url}/v2.0/api/company_stamp
```

**Body:**
```json
{
  "company_stamp": {
    "name": "Stamp Name",
    "description": "Description",
    "stamp": {
      "path": "data:image/png;base64,iVBORw0K..."
    },
    "auth": {
      "allow_all_members": false,
      "groups": ["group_id_1"],
      "members": ["user@example.com"]
    }
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| company_stamp.name | string | Y | Stamp name |
| company_stamp.stamp.path | string | Y | Base64-encoded image — supported formats: `data:image/png;base64,...` or `data:image/ozdpi,...` |
| company_stamp.auth.groups | array(string) | N | Authorized group IDs |
| company_stamp.auth.members | array(string) | N | Authorized member emails |
| company_stamp.auth.allow_all_members | boolean | N | Allow all members |
| company_stamp.auth.auth_details | array | N | Additional auth detail entries (not documented in official API spec) |

---

### Update Stamp 📘 Dev Guide
```
PATCH {api_url}/v2.0/api/company_stamp/{stamp_id}
```

**Body:** Same structure as Add Stamp.

---

### Delete Stamp 📘 Dev Guide
```
DELETE {api_url}/v2.0/api/company_stamp/{stamp_id}
```
