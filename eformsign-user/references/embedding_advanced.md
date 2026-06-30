# eformsign Embedding — Advanced Options, Callbacks & Examples

## Advanced Options

### prefills (Batch Preview)

Used to display multiple document variations sequentially in preview mode:

```javascript
prefills: [
  {
    document_name: "Contract - Option A",
    fields: [
      { id: "FieldName", value: "Value A" }
    ],
    form_parameters: [
      { id: "jsonDataset", value: "{\"key\":\"value\"}" }
    ]
  },
  {
    document_name: "Contract - Option B",
    fields: [
      { id: "FieldName", value: "Value B" }
    ]
  }
]
```

### form_parameters (Dataset Mapping)

Used with dynamic templates that bind external datasets:

```javascript
form_parameters: [
  {
    id: "jsonDataset",                        // Dataset identifier defined in the template
    value: "{\"data\":{\"key\":\"value\"}}"   // JSON-formatted string
  }
]
```

### userdata (Custom Signature/Stamp)

Pre-load custom signature or company stamp images:

```javascript
userdata: {
  signatures: [
    {
      type: "signature",           // "signature" | "initial" | "stamp"
      path: {
        type: "image/png",         // "image/png" | "draw"
        text: "My Signature",      // Label
        path: "data:image/png;base64,..."  // Base64-encoded image
      }
    }
  ],
  company_stamps: [
    {
      type: "company_stamp",
      path: {
        type: "image",
        text: "Company Seal",
        path: "data:image/png;base64,..."  // Base64-encoded image
      }
    }
  ]
}
```

### ozd_file (Document from OZD file)

Embed a document viewer using a Base64-encoded OZD file directly:

```javascript
ozd_file: {
  data: "T1pQAwAAARIAAE5vUGFzc3dvcmRfRW50ZXJlZI6vbyH6..."  // Base64-encoded OZD file
}
```

### doc_pdf_list (Multi-document PDF Preview)

Display multiple documents sequentially in preview mode:

```javascript
doc_pdf_list: [
  "7be5a8371ca24f08a567cec01d105717",
  "c79ea00e96854c13bea75e18844190fb"
]
```

### viewer_event (Dynamic Viewer Scripts)

Execute scripts after the viewer finishes loading (e.g., to pre-fill OZ report fields programmatically):

```javascript
viewer_event: {
  script: {
    postinitialize:
      "var comp = GetInputComponent('손글씨 1');" +
      "if(comp) comp.SetText('손글씨 1');"
  }
}
```

### return_fields

Specify field IDs whose values should be returned in the success_callback after document completion:

```javascript
return_fields: ["FieldName1", "FieldName2"]
```

Access in success_callback:
```javascript
var success_callback = function(response) {
  if (response.code == "-1") {
    var value1 = response.field_values["FieldName1"];
    var value2 = response.field_values["FieldName2"];
  }
};
```

---

## Callback Functions

```javascript
// Success callback: called when document creation/processing completes
var success_callback = function(response) {
  if (response.code == "-1") {   // string "-1" comparison (use == not ===)
    // Completed successfully
    console.log("Document ID:", response.document_id);
    // If return_fields was set:
    console.log("Field values:", response.field_values);
  }
};

// Error callback: called when an error occurs
var error_callback = function(response) {
  console.error("Error code:", response.code);
  console.error("Error message:", response.message);
};

// Action callback: called when a user action occurs (send, save, cancel, etc.)
var action_callback = function(response) {
  console.log("Action type:", response.action_type);
  console.table(response.data);
};
```

**success_callback response.code values:**

| Code | Meaning |
|------|---------|
| "-1" | Successfully completed (string value, use `==` not `===`) |
| Other | Error occurred |

---

## Full Implementation Examples

### Vanilla HTML — Document Creation

```html
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <title>eformsign Embedding</title>
</head>
<body>
  <iframe id="eformsign_iframe" style="width:100%; height:800px; border:none;"></iframe>

  <script src="https://www.eformsign.com/plugins/jquery/jquery.min.js"></script>
  <script src="https://www.eformsign.com/lib/js/efs_embedded_v2.js"></script>
  <script src="https://www.eformsign.com/lib/js/efs_embedded_form.js"></script>

  <script>
    var document_option = {
      company: {
        id: "YOUR_COMPANY_ID",
        country_code: "kr"
      },
      mode: {
        type: "01",
        template_id: "YOUR_TEMPLATE_ID"
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
      prefill: {
        document_name: "입사 확인서_홍길동",
        fields: [
          { id: "EmployeeName", value: "홍길동", enabled: false },
          { id: "Department",   value: "개발팀", enabled: false },
          { id: "StartDate",    value: "2024-01-15" }
        ],
        recipients: [
          {
            step_idx: "2",
            step_type: "05",
            name: "홍길동",
            id: "hong@company.com",
            use_mail: true,
            use_sms: false,
            disabled_contents: ["all"]
          }
        ],
        comment: "아래 서류를 확인하고 서명해 주세요."
      },
      return_fields: ["EmployeeName", "Department"]
    };

    var success_callback = function(response) {
      if (response.code == "-1") {
        console.log("완료. 문서 ID:", response.document_id);
        console.log("필드값:", response.field_values);
      }
    };

    var error_callback = function(response) {
      alert("오류: " + response.message);
    };

    var action_callback = function(response) {
      console.log("액션:", response.action_type);
    };

    var eformsign = new EformSignDocument();
    eformsign.document(document_option, "eformsign_iframe",
      success_callback, error_callback, action_callback);
    eformsign.open();
  </script>
</body>
</html>
```

### Vanilla HTML — Template Creation (Form Builder)

```html
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <title>템플릿 생성</title>
</head>
<body>
  <iframe id="eformsign_iframe" style="width:100%; height:900px; border:none;"></iframe>

  <script src="https://www.eformsign.com/plugins/jquery/jquery.min.js"></script>
  <script src="https://www.eformsign.com/lib/js/efs_embedded_v2.js"></script>
  <script src="https://www.eformsign.com/lib/js/efs_embedded_form.js"></script>

  <script>
    var template_option = {
      company: {
        id: "YOUR_COMPANY_ID",
        country_code: "kr"
      },
      mode: {
        type: "01",             // "01": new, "02": edit, "03": duplicate
        template_type: "form"   // "form": Form Builder, "unstructured_form": file upload
        // template_id: "..."  — required for type "02" and "03"
      },
      user: {
        type: "01",
        id: "admin@company.com",
        access_token: "YOUR_ACCESS_TOKEN",
        refresh_token: "YOUR_REFRESH_TOKEN"
      },
      layout: {
        lang_code: "ko"
      }
    };

    var eformsign = new EformSignTemplate();
    eformsign.template(template_option, "eformsign_iframe",
      function(res) { if (res.code == "-1") console.log("템플릿 저장 완료"); },
      function(err) { console.error(err); },
      function(action) { console.log(action); }
    );
    eformsign.open();
  </script>
</body>
</html>
```

### React

```jsx
import { useEffect } from 'react';

function EformsignEmbed({ accessToken, refreshToken, templateId, prefillData }) {
  useEffect(() => {
    const loadScript = (src) => new Promise((resolve) => {
      const script = document.createElement('script');
      script.src = src;
      script.onload = resolve;
      document.body.appendChild(script);
    });

    const init = async () => {
      await loadScript('https://www.eformsign.com/plugins/jquery/jquery.min.js');
      await loadScript('https://www.eformsign.com/lib/js/efs_embedded_v2.js');
      await loadScript('https://www.eformsign.com/lib/js/efs_embedded_form.js');

      const option = {
        company: { id: 'YOUR_COMPANY_ID', country_code: 'kr' },
        mode: { type: '01', template_id: templateId },
        user: {
          type: '01',
          id: 'user@company.com',
          access_token: accessToken,
          refresh_token: refreshToken
        },
        layout: { lang_code: 'ko', header: true, footer: true },
        prefill: prefillData || {}
      };

      window.eformsign.document(
        option,
        'eformsign_container',
        (res) => { if (res.code === '-1') console.log('완료:', res.document_id); },
        (err) => { console.error('오류:', err.message); },
        (action) => { console.log('액션:', action.action_type); }
      );
      window.eformsign.open();
    };

    init();
  }, [accessToken, templateId]);

  // ⚠️ Must use <iframe>, NOT <div>. The SDK sets `src` directly on this element.
  const iframeStyle = { width: '100%', height: '800px', border: 'none' };
  return <iframe id="eformsign_container" style={iframeStyle} />;
}
```
