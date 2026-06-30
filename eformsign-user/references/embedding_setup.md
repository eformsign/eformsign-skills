# eformsign Embedding — Script Loading & SDK Objects

## Load Scripts

Load in order inside `<head>` or at the bottom of `<body>`:

```html
<!-- Cloud (production) -->
<script src="https://www.eformsign.com/plugins/jquery/jquery.min.js"></script>
<script src="https://www.eformsign.com/lib/js/efs_embedded_v2.js"></script>
<script src="https://www.eformsign.com/lib/js/efs_embedded_form.js"></script>

<!-- Local/custom domain instance: load scripts from the target server instead -->
<!-- <script src="http://YOUR_EFORMSIGN_HOST/plugins/jquery/jquery.min.js"></script> -->
<!-- <script src="http://YOUR_EFORMSIGN_HOST/lib/js/efs_embedded_v2.js"></script>   -->
<!-- <script src="http://YOUR_EFORMSIGN_HOST/lib/js/efs_embedded_form.js"></script> -->
```

The container element **must be an `<iframe>`** — the library sets the `src` attribute directly on this element (applies to both cloud and on-premise):
```html
<iframe id="eformsign_iframe" style="width:100%; height:800px; border:none;"></iframe>
```

> **Note (applies to all environments)**: Do NOT use a `<div>` as the container. The JS calls `$('#id').attr('src', url)` which only works on `<iframe>` elements.

> **⚠️ SDK Global Variable Collision (on-premise confirmed, likely affects cloud too)**
>
> **The two conflicting constants are `UPDATE` and `PREVIEW`.** Both files define these names but with different values.
>
> `efs_embedded_v2.js` and `efs_embedded_form.js` define conflicting global constants:
>
> | Constant | efs_embedded_v2.js | efs_embedded_form.js |
> |----------|--------------------|----------------------|
> | `UPDATE` | `'04'` | `'02'` ← overwrites |
> | `PREVIEW` | `'03'` | `'04'` ← overwrites |
>
> When both scripts are loaded (as official docs instruct), loading `efs_embedded_form.js` **last** overwrites the v2.js constants. This causes:
> - `EformSignDocument` mode `'02'` (sign) → triggers "외부자는 문서를 수정할 수 없습니다" ("External users cannot edit the document") alert (hits UPDATE branch)
> - `EformSignDocument` mode `'03'` (preview) → missing `&viewFlag=true&document_id=...` params (PREVIEW branch skipped)
>
> **Workarounds:**
>
> _Option A — If the page only uses `EformSignDocument`:_ Do **not** load `efs_embedded_form.js` at all.
>
> _Option B — If the page needs both SDKs:_ Restore the correct constants **immediately before each individual SDK call** — both before `.document()`/`.template()` AND before `.open()`:
> ```javascript
> function restoreV2Constants() {
>   window.WRITE   = '01'; window.SIGN    = '02';
>   window.PREVIEW = '03'; window.UPDATE  = '04';
> }
> function restoreFormConstants() {
>   window.CREATE  = '01'; window.UPDATE  = '02';
>   window.CLONE   = '03'; window.PREVIEW = '04';
> }
>
> // ✅ Correct usage — restore before EVERY call (document/template AND open)
> restoreV2Constants();
> efsDoc.document(document_option, 'iframe_id', successCb, errorCb);
> restoreV2Constants();   // restore again — form.js may have re-overwritten constants
> efsDoc.open();
>
> restoreFormConstants();
> efsTemplate.template(template_option, 'iframe_id', successCb, errorCb);
> restoreFormConstants(); // restore again before open()
> efsTemplate.open();
>
> // ❌ Wrong — missing restore before open() causes silent misbehavior
> // restoreFormConstants();
> // efsTemplate.template(...);
> // efsTemplate.open();  ← constants may have been overwritten again
> ```

### Custom Domain (Local/On-premise only)

> The following applies **only** when using a local or on-premise eformsign instance. Cloud (`www.eformsign.com`) users can skip this section.

**1. Load scripts from your own server** (not the cloud CDN):
```html
<script src="http://YOUR_EFORMSIGN_HOST/plugins/jquery/jquery.min.js"></script>
<script src="http://YOUR_EFORMSIGN_HOST/lib/js/efs_embedded_v2.js"></script>
<script src="http://YOUR_EFORMSIGN_HOST/lib/js/efs_embedded_form.js"></script>
```

**2. Call `setDomain()` before `open()`**:
```javascript
var eformsign = new EformSignDocument(); // or EformSignTemplate
eformsign.setDomain("http://YOUR_EFORMSIGN_HOST");
eformsign.document(document_option, "eformsign_iframe", ...);
eformsign.open();
```

Without `setDomain()`, the library defaults to `https://www.eformsign.com` for the iframe URL regardless of where the scripts were loaded from.

---

## Embedding Objects

| Object | Purpose |
|--------|---------|
| `EformSignDocument` | Template-based document creation, processing, and preview |
| `EformSignTemplate` | Template creation/editing/duplication, unstructured form creation |

---

## EformSignDocument

Used for document workflows based on existing templates.

```javascript
var eformsign = new EformSignDocument();
eformsign.document(document_option, "container_id", success_callback, error_callback, action_callback);
eformsign.open();
```

**Mode types:**

| type | Purpose | Required fields |
|------|---------|----------------|
| "01" | Create new document from template | `template_id` |
| "02" | Process received document (sign/fill) | `template_id` + `document_id` |
| "03" | Preview created document (read-only) | `template_id` + `document_id` |

> **Note**: `template_id` is required for **all** mode types. For modes "02" and "03", `document_id` is additionally required. `prefill` options do not work in mode "03".
> `template_version` is only valid for mode "01".

---

## EformSignTemplate

Used for template management and unstructured form creation (Form Builder embedding).

```javascript
var eformsign = new EformSignTemplate();
eformsign.template(template_option, "container_id", success_callback, error_callback, action_callback);
eformsign.open();
```

**Mode types:**

| type | template_type | Purpose | Required field |
|------|--------------|---------|----------------|
| "01" | `"unstructured_form"` | Create document from uploaded file | — |
| "01" | `"form"` | Create new template (Form Builder) | — |
| "02" | `"form"` | Edit existing template | `template_id` |
| "03" | `"form"` | Duplicate template | `template_id` |

**template_option structure:**
```javascript
var template_option = {
  company: {
    id: "YOUR_COMPANY_ID",
    country_code: "kr"
  },
  mode: {
    type: "01",               // "01": create, "02": edit, "03": duplicate
    template_type: "form"     // "form" | "unstructured_form"
    // template_id required for type "02" and "03"
  },
  user: {
    type: "01",
    id: "user@company.com",
    access_token: "YOUR_ACCESS_TOKEN",
    refresh_token: "YOUR_REFRESH_TOKEN"
  },
  layout: {
    lang_code: "ko",
    header: true,
    footer: true
  },
  prefill: {                  // Optional: pre-configure template settings
    template_name: "My Template",
    is_form_id_numbering: true,     // Auto-number field IDs (default: true)
    quick_processing: false,        // Skip send confirmation popup
    step_settings: [                // Pre-configure workflow steps
      {
        step_type: "05",            // "05": participant, "06": reviewer
        step_name: "서명자",
        use_mail: true,
        use_sms: false,
        recipients: [
          { id: "signer@company.com", name: "홍길동", recipient_type: "01" }
        ],
        auth: {
          password: "",
          valid: { day: 7, hour: 0 }
        }
      }
    ]
  },
  template_file: {            // Optional (unstructured_form only): file to use as template base
    name: "contract.pdf",
    mime: "application/pdf",
    data: "JVBERi0xLjQK..."  // Base64-encoded file
  }
};
```
