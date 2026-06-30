# eformsign Embedding — document_option Configuration

## Full document_option Structure

```javascript
var document_option = {
  company: {
    id: "",              // Required: Company ID (from admin console > Company Info)
    country_code: "kr",  // Country code: "kr", "us", "jp"
    user_key: ""         // Optional: external user identifier key
  },
  mode: {
    type: "01",          // "01": create, "02": process, "03": preview
    template_id: "",     // Required for ALL mode types
    document_id: "",     // Required for type "02" and "03"
    template_version: "" // Optional: only valid for type "01" (create)
  },
  user: {
    type: "01",          // "01": company member (token-based), "02": external user
    id: "",              // Member email (when type is "01")
    access_token: "",    // Access Token from API (when type is "01")
    refresh_token: "",   // Refresh Token from API (when type is "01")
    external_token: "",  // outside_token from Webhook doc_request_participant (when type is "02")
    external_user_info: {
      name: ""           // External user name (when type is "02")
    }
  },
  layout: {
    lang_code: "ko",          // Language: "ko", "en", "ja"
    header: true,             // Show top header
    footer: true,             // Show bottom footer (action buttons)
    zoom: "1.0",              // Content scale factor (default: "1.0")
    context_menu: true,       // Enable right-click menu (default: true)
    popup: {
      email: true,            // Show email option in viewer popup (default: true)
      sms: true               // Show SMS option in viewer popup (default: true)
    },
    viewer_toolbar: {
      "toolbar.save": "false",   // Hide save button (use string "false"/"true", not boolean)
      "toolbar.print": "false"   // Hide print button
    }
  },
  prefill: {
    document_name: "",        // Pre-set document name
    fields: [],               // Auto-populate input fields (see below)
    recipients: [],           // Pre-set recipients (see below)
    comment: "",              // Request message to next recipient
    is_hidden_stamp: false,   // Whether to hide company stamp watermark (default: false)
    quick_processing: false,  // Skip send confirmation popup (default: false)
    send_completed_document_pdf: false, // Send PDF of completed document
    use_referer: false,       // Show reference person button
    referers: {               // Reference person configuration
      groups: [{ id: "", disabled: false }],
      members: [{ id: "", disabled: false, required: false }]
    },
    auth: {                   // Document access authentication
      password: "",           // Access password
      password_hint: "",      // Password hint text
      valid: {
        day: 7,               // Expiration days (0-999)
        hour: 0               // Expiration hours (0-23)
      }
    }
  },
  prefills: [],               // Batch preview configuration (see Advanced Options)
  form_parameters: [],        // Dataset mapping for dynamic templates (see Advanced Options)
  userdata: {},               // Custom signature/stamp data (see Advanced Options)
  return_fields: [],          // Field IDs to return in success_callback (see Advanced Options)
  ozd_file: {                 // Optional: Base64-encoded OZD file for document creation
    data: "T1pQAwAA..."
  },
  doc_pdf_list: [],           // Optional: Array of document IDs for multi-document PDF preview
  viewer_event: {             // Optional: Scripts executed when viewer initializes
    script: {
      postinitialize: "var comp = GetInputComponent('Field1'); if(comp) comp.SetText('value');"
    }
  }
};
```

---

## User Type Configuration

### Type 01: Company Member (Access Token)
```javascript
user: {
  type: "01",
  id: "user@company.com",
  access_token: "YOUR_ACCESS_TOKEN",
  refresh_token: "YOUR_REFRESH_TOKEN",
  internal_token: ""   // Used when a company member processes (signs/approves) a received document
                       // Whether strictly required is unverified — include when available
}
```
- Access Token must be obtained via the API beforehand
- Automatically uses refresh_token when the token expires
- `internal_token` is used when a company member processes (signs/approves) a document they received. Official docs mention this field but whether omitting it causes failure has not been verified.

### Type 02: External User

**Case A — External user creating a new document (mode "01"):**
```javascript
user: {
  type: "02",
  // external_token not required here
  external_user_info: {
    name: "John Doe"   // External user name (only name is supported)
  }
}
```

**Case B — External user processing/signing a received document (mode "02"):**
```javascript
user: {
  type: "02",
  external_token: "TOKEN_FROM_WEBHOOK",  // outside_token from Webhook doc_request_participant event
  auth_id: "TOKEN_FROM_WEBHOOK",         // ⚠️ Required: same value as external_token
                                          // SDK's getViewer() checks _auth_id to select the correct
                                          // viewer URL (external_view_service.html). Without it,
                                          // the iframe loads /eform/account/authenticate.html instead.
  external_user_info: {
    name: "John Doe"
  }
}
```

> **Note on `auth_id`**: This field is **not documented in the official docs** but is required by the SDK internals (`efs_embedded_v2.js` → `getViewer()`). Without a truthy `auth_id`, the SDK sends the external user to the login page instead of the signing page.

---

## Mode Type Configuration

### Type 01: Create Document (new)
```javascript
mode: {
  type: "01",
  template_id: "YOUR_TEMPLATE_ID",   // Required
  template_version: ""                // Optional: omit for latest version
}
```

### Type 02: Process Document (sign/fill)
```javascript
mode: {
  type: "02",
  template_id: "YOUR_TEMPLATE_ID",   // Required
  document_id: "DOCUMENT_ID"         // Required
}
```

### Type 03: Preview Document (read-only)
```javascript
mode: {
  type: "03",
  template_id: "YOUR_TEMPLATE_ID",   // Required
  document_id: "DOCUMENT_ID"         // Required
}
```
> `prefill` options have no effect in mode "03".

---

## Layout Options

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `lang_code` | String | — | Interface language: `"ko"`, `"en"`, `"ja"` |
| `header` | Boolean | `true` | Show top navigation bar |
| `footer` | Boolean | `true` | Show bottom action buttons |
| `zoom` | String | `"1.0"` | Content scale factor |
| `context_menu` | Boolean | `true` | Enable right-click context menu |
| `popup.email` | Boolean | `true` | Show email option in viewer popup |
| `popup.sms` | Boolean | `true` | Show SMS option in viewer popup |
| `viewer_toolbar["toolbar.save"]` | String | `"true"` | Show/hide save button (`"true"`/`"false"` as strings) |
| `viewer_toolbar["toolbar.print"]` | String | `"true"` | Show/hide print button (`"true"`/`"false"` as strings) |

---

## Prefill (Auto-populate)

### prefill.fields

```javascript
prefill: {
  fields: [
    {
      id: "FieldName",    // Required: Field ID defined in the template
      value: "Value",     // Initial field value
      enabled: true,      // Whether the field is editable (default: inherits template setting)
      required: true      // Whether the field is mandatory (default: inherits template setting)
    }
  ]
}
```

- Omitting `enabled`/`required` inherits the template's default configuration
- Inline settings override template defaults

### prefill.recipients

```javascript
prefill: {
  recipients: [
    {
      step_idx: "2",              // Workflow step index ("2" = first recipient)
      step_type: "05",            // See step_type table below
      recipient_type: "02",       // "01": member, "02": external (required for step_type 02-04)
      name: "Signer Name",
      id: "signer@example.com",   // Email or member ID
      email: "signer@example.com",// Email address (for step_type "03" only)
      sms: "01012345678",         // Phone number
      use_mail: true,             // Send email notification
      use_sms: false,             // Send SMS notification
      auth: {                     // Per-recipient authentication
        password: "",
        password_hint: "",
        valid: { day: 7, hour: 0 }
      },
      document_link: "",          // Custom document URL (optional)
      disabled_contents: []       // Lock specific recipient fields from being edited
                                  // Values: "id", "name", "sms", "use_mail", "use_sms",
                                  //         "auth", "comment" or ["all"]
    }
  ],
  comment: "Please sign the document."
}
```

**step_type codes:**

| Code | Meaning |
|------|---------|
| "01" | Internal signer (complete) |
| "02" | Internal approver |
| "03" | External recipient |
| "04" | Internal designated member |
| "05" | External signer (participant) |
| "06" | Internal reviewer |

### prefill.auth

Sets document-level access authentication:

```javascript
prefill: {
  auth: {
    password: "1234",
    password_hint: "Last 4 digits of your phone number",
    valid: {
      day: 7,    // Valid for 7 days
      hour: 0
    }
  }
}
```
