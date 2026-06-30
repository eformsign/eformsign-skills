# eformsign SDK Findings & Known Issues

> This document records findings from direct analysis of the official docs and SDK source files
> (`efs_embedded_v2.js`, `efs_embedded_form.js`). Focuses on items missing or incorrect in official docs.
>
> Verified on: eformsign on-premise (local), Spring Boot hr-onboarding sample app

---

## 1. Items Incorrect in Official Documentation

### viewer_toolbar Key/Value Format

| Source | Format |
|--------|--------|
| Official docs | `{ "toolbar.save": "false", "toolbar.print": "false" }` — dot-notation string keys, string values |
| embedding.md (before fix) | `{ save: true, print: true }` — short keys, boolean values |

**Correct format:**
```javascript
layout: {
  viewer_toolbar: {
    "toolbar.save": "false",    // string "true"/"false", not boolean
    "toolbar.print": "false"
  }
}
```

---

## 2. Items in Official Docs but Missing from embedding.md

### 2-1. user.internal_token (type "01")

Token used when a company member (type "01") processes (signs/approves) a document they received.
Present in the official docs' user object but was missing from embedding.md.

```javascript
user: {
  type: "01",
  id: "user@company.com",
  access_token: "...",
  refresh_token: "...",
  internal_token: "..."   // used when processing a received document
}
```

### 2-2. External User (type "02") — New Document Creation Case

Official docs distinguish two cases for type "02":
- **mode "01" (create new)**: `external_token` not required — only `external_user_info.name` needed
- **mode "02" (process received)**: `external_token` + `external_user_info.name` required

embedding.md previously implied `external_token` was always required.

### 2-3. Three Top-Level Options Missing

| Option | Purpose |
|--------|---------|
| `ozd_file` | Create document from a Base64-encoded OZD file |
| `doc_pdf_list` | Multi-document PDF preview (array of document IDs) |
| `viewer_event.script` | OZ Report script executed after viewer initializes (`postinitialize` event) |

### 2-4. template_option.prefill Advanced Fields Missing

Prefill options exclusive to `EformSignTemplate` were partially missing:

| Field | Description |
|-------|-------------|
| `prefill.template_name` | Pre-set template title |
| `prefill.step_settings` | Pre-configure workflow steps (recipients, auth, notifications) |
| `prefill.is_form_id_numbering` | Auto-number field IDs (default: true) |
| `prefill.quick_processing` | Skip send confirmation popup |
| `template_file` | Base file for unstructured form creation (Base64) |

---

## 3. Items Not in Official Docs — Found Only via SDK Source Analysis

### 3-1. ⚠️ Global Constant Collision (Critical Bug)

**Symptom**: Loading `efs_embedded_v2.js` and `efs_embedded_form.js` together causes both files to
declare the same global constants with different values, resulting in a collision.

**Conflicting constants:**

| Constant | efs_embedded_v2.js | efs_embedded_form.js (loaded later → overwrites) |
|----------|--------------------|--------------------------------------------------|
| `UPDATE` | `'04'` | `'02'` |
| `PREVIEW` | `'03'` | `'04'` |

**Symptoms:**
- `EformSignDocument` mode `'02'` (sign) → "External users cannot modify documents" alert → iframe URL is empty
- `EformSignDocument` mode `'03'` (preview) → `&viewFlag=true&document_id=...` params missing → opens template creation screen instead

**Root cause** (`efs_embedded_v2.js`):
```javascript
// Inside getEformSignUrl()
} else if (target._mode_type === UPDATE) {   // UPDATE='02' (overwritten by form.js)
  if (target._user_type === USER_TYPE_INTERNAL) { ... }
  else { window.alert('External users cannot modify documents.'); }  // external users fall here
```
```javascript
// Inside getEformSignUrl() else branch
} else if (target._mode_type === PREVIEW) { // PREVIEW='04' (overwritten by form.js)
  eformSignUrl += '&document_id=...&viewFlag=true...';  // mode '03' skips this branch
}
```

**Workaround A** — Pages using only `EformSignDocument`: remove `efs_embedded_form.js` from the page.

**Workaround B** — Pages using both SDKs simultaneously: restore constants before each SDK call:
```javascript
function restoreV2Constants() {
  window.WRITE = '01'; window.SIGN = '02';
  window.PREVIEW = '03'; window.UPDATE = '04';
}
function restoreFormConstants() {
  window.CREATE = '01'; window.UPDATE = '02';
  window.CLONE = '03'; window.PREVIEW = '04';
}

// Usage example
restoreV2Constants();
previewEformsign.document(document_option, 'iframe_id', successCb, errorCb);
restoreV2Constants();
previewEformsign.open();

restoreFormConstants();
templateEformsign.template(template_option, 'iframe_id', successCb, errorCb);
restoreFormConstants();
templateEformsign.open();
```

### 3-2. ⚠️ user.auth_id — Undocumented Required Field for External User Signing

**Symptom**: Without `user.auth_id`, external users accessing a signing link are redirected to the
eformsign login page (`/eform/account/authenticate.html`) instead of the signing page.

**Root cause** (`efs_embedded_v2.js` → `getViewer()`):
```javascript
} else if (target._user_type === USER_TYPE_EXTERNAL) {
  if (target._mode_type === WRITE) {
    viewer_url = '/eform/document/external_user_view_service.html';
  } else {
    if (target._auth_id) {                                    // ← this condition is the key
      viewer_url = '/eform/document/external_view_service.html';
    } else {
      viewer_url = '/eform/account/authenticate.html';        // no auth_id → login page
    }
  }
}
```

**Fix**: Set `auth_id` to the same value as `external_token`:
```javascript
user: {
  type: "02",
  external_token: "TOKEN_FROM_WEBHOOK",
  auth_id: "TOKEN_FROM_WEBHOOK",          // must equal external_token
  external_user_info: { name: "John Doe" }
}
```

> **Why it's undocumented**: `auth_id` is automatically injected in eformsign's internal link flow
> (after email authentication). Manual setting is only required in the embedding scenario.
