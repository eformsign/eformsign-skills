# eformsign Webhook Guide

## Table of Contents
1. [Overview](#overview)
2. [Registering a Webhook](#registering-a-webhook)
3. [Request Body Structure](#request-body-structure)
4. [Event Types](#event-types)
5. [Signature Verification](#signature-verification)
6. [Server Implementation Examples](#server-implementation-examples)

---

## Overview

eformsign Webhooks send an HTTP POST request to your endpoint whenever a document event occurs (created, completed, deleted, etc.). This allows you to receive events in real time without polling.

---

## Registering a Webhook

1. Admin console > **Connect > API/Webhook > Webhook Management** tab
2. Click **Add Webhook**
3. Fill in:
   - **Name**: Identifier for this webhook
   - **Endpoint URL**: Your server URL to receive events (HTTPS recommended)
   - **Active**: Enable/disable
   - **Apply to**:
     - All documents
     - Documents without a template only
     - Specific templates
   - **Verification type**: See below

### Verification Types

| Type | Header | Description |
|------|--------|-------------|
| None | — | No verification, accept all requests |
| Bearer Token | `Authorization: Bearer {token}` | Verify against a pre-configured token |
| Basic Auth | `Authorization: Basic {Base64(ID:PW)}` | Verify with Base64-encoded credentials |
| eformsign Signature | `eformsign_signature: {signature}` | Verify with the public key (most secure) |

### Webhook Management
- **View Key**: See the public key for eformsign Signature verification
- **Test**: Send a test request to the configured URL
- **Edit / Delete**: Modify or remove the webhook

---

## Request Body Structure

```json
{
  "webhook_id": "webhook_id",
  "webhook_name": "webhook_name",
  "company_id": "company_id",
  "event_type": "document",
  "document": { ... },
  "ready_document_pdf": { ... }
}
```

### document object (event_type: "document")

> ⚠️ **Actual field names differ from what you might expect:**
> - `id` (NOT `document_id`)
> - `status` (NOT `document_status`)
> - `document_title` (NOT `document_name`)

```json
{
  "id": "document_id",
  "document_title": "Document Name",
  "template_id": "template_id",
  "template_name": "Template Name",
  "template_version": "5",
  "workflow_seq": 2,
  "workflow_name": "참여자 1",
  "history_id": "history_id",
  "status": "doc_request_participant",
  "action": "",
  "editor_id": "creator@company.com",
  "outside_token": "87c3fa9616d44fbf9f15419705bd8354",
  "updated_date": 1773912823669,
  "mass_job_request_id": "",
  "comment": "Please sign the document."
}
```

| Field | Type | Description |
|-------|------|-------------|
| id | String | Document ID |
| document_title | String | Document name |
| template_id | String | Template ID |
| template_name | String | Template name |
| template_version | String | Template version |
| workflow_seq | Integer | Current workflow step index |
| workflow_name | String | Current workflow step name |
| history_id | String | Event history ID |
| status | String | Document status (see Event Types) |
| action | String | Action taken |
| editor_id | String | Member ID who triggered the event |
| outside_token | String | **External signing token** — used as `external_token` in iframe embedding for external signers. Non-empty only when the current step involves an external participant. |
| updated_date | Long | Event timestamp (ms) |
| mass_job_request_id | String | Bulk job ID (empty if not bulk) |
| comment | String | Message to recipient |

### ready_document_pdf object (event_type: "ready_document_pdf")
```json
{
  "document_id": "document_id",
  "document_name": "Document Name",
  "pdf_url": "PDF_DOWNLOAD_URL",
  "pdf_url_expiry": "2024-01-15T12:00:00Z"
}
```

---

## Event Types

### document events — status values
| Status | When it fires |
|--------|--------------|
| doc_tempsave | Draft saved |
| doc_create | Document sent/created (outside_token is empty at this stage) |
| doc_request_participant | Sent to a participant (external signer) — **outside_token is populated here** |
| doc_accept_participant | Participant accepted/signed |
| doc_reject_participant | Rejected by a participant |
| doc_complete | All participants finished |
| doc_deleted | Document deleted |
| doc_cancel | Document cancelled |
| doc_request_external | *(Legacy workflow only)* Sent to external recipient — use `doc_request_participant` for current workflows |
| doc_accept_external | *(Legacy workflow only)* External recipient accepted |
| doc_reject_external | *(Legacy workflow only)* External recipient rejected |

> **Note**: For external signing iframe embedding, listen for `doc_request_participant` and use the `outside_token` value as `external_token` in `EformSignDocument`. The `doc_create` event fires first but has an empty `outside_token`.

> **⚠️ Common mistake — `doc_request_outsider`**: This string appears in the eformsign API documentation as an **internal action type code** (code 030), but it is **NOT a Webhook `status` value**. Do not use it as a Webhook event name. The correct Webhook event for external signer requests is `doc_request_participant`.

### ready_document_pdf events
Fires when the PDF file is ready after document completion. Use `pdf_url` to download the PDF.

---

## Signature Verification

When using the **eformsign Signature** verification type, verify the authenticity of incoming requests.

### Verification Process
1. Get the **public key** from the Webhook settings page and store it
2. Extract the `eformsign_signature` header value from the incoming request
3. Convert the request body to UTF-8 bytes
4. Verify the signature using the public key with SHA256withECDSA

### Java
```java
import java.security.*;
import java.security.spec.*;

public class EformsignWebhookVerifier {

    public static boolean verifySignature(String publicKeyHex, String signatureHex, byte[] body) {
        try {
            byte[] publicKeyBytes = hexToBytes(publicKeyHex);
            KeyFactory kf = KeyFactory.getInstance("EC");
            X509EncodedKeySpec keySpec = new X509EncodedKeySpec(publicKeyBytes);
            PublicKey publicKey = kf.generatePublic(keySpec);

            Signature sig = Signature.getInstance("SHA256withECDSA");
            sig.initVerify(publicKey);
            sig.update(body);
            // ⚠️ Do NOT use new BigInteger(hex, 16).toByteArray() — may strip leading zeros.
            // Use hex decoding directly:
            return sig.verify(hexToBytes(signatureHex));
        } catch (Exception e) {
            return false;
        }
    }

    private static byte[] hexToBytes(String hex) {
        int len = hex.length();
        byte[] data = new byte[len / 2];
        for (int i = 0; i < len; i += 2)
            data[i / 2] = (byte) ((Character.digit(hex.charAt(i), 16) << 4)
                + Character.digit(hex.charAt(i + 1), 16));
        return data;
    }
}
```

### Python
> **⚠️ Library requirement**: Use the `ecdsa` package (`pip install ecdsa`). Do NOT use `cryptography`, `pycryptodome`, or `Crypto` — they use different APIs and curve names. The curve is always `NIST256p`.

```python
# pip install ecdsa
import binascii
from ecdsa import VerifyingKey, NIST256p
from ecdsa.util import sigdecode_der

def verify_eformsign_signature(public_key_hex: str, signature_hex: str, body: bytes) -> bool:
    try:
        public_key_bytes = binascii.unhexlify(public_key_hex)
        vk = VerifyingKey.from_string(public_key_bytes, curve=NIST256p)
        signature_bytes = binascii.unhexlify(signature_hex)
        return vk.verify(signature_bytes, body, sigdecode=sigdecode_der)
    except Exception:
        return False
```

### PHP
```php
function verifyEformsignSignature(string $publicKeyHex, string $signatureHex, string $body): bool {
    $publicKeyDer = hex2bin($publicKeyHex);
    $publicKeyPem = "-----BEGIN PUBLIC KEY-----\n"
        . chunk_split(base64_encode($publicKeyDer), 64, "\n")
        . "-----END PUBLIC KEY-----\n";

    $publicKey = openssl_pkey_get_public($publicKeyPem);
    if (!$publicKey) return false;

    $result = openssl_verify($body, hex2bin($signatureHex), $publicKey, OPENSSL_ALGO_SHA256);
    return $result === 1;
}
```

---

## Server Implementation Examples

### Python (FastAPI)
```python
from fastapi import FastAPI, Request, HTTPException
import json

app = FastAPI()
EFORMSIGN_PUBLIC_KEY = "YOUR_PUBLIC_KEY_HEX"  # from Webhook settings

@app.post("/webhook/eformsign")
async def handle_eformsign_webhook(request: Request):
    body = await request.body()

    signature = request.headers.get("eformsign_signature")
    if signature and not verify_eformsign_signature(EFORMSIGN_PUBLIC_KEY, signature, body):
        raise HTTPException(status_code=401, detail="Invalid signature")

    payload = json.loads(body)
    event_type = payload.get("event_type")

    if event_type == "document":
        document = payload.get("document", {})
        status = document.get("status")          # "status" not "document_status"
        doc_id = document.get("id")              # "id" not "document_id"
        outside_token = document.get("outside_token", "")

        if status == "doc_request_participant" and outside_token:
            # Store outside_token for external signing embedding
            await handle_external_signing(doc_id, outside_token)
        elif status == "doc_complete":
            await handle_document_complete(doc_id, document)
        elif status == "doc_reject_participant":
            await handle_document_rejected(doc_id, document)

    elif event_type == "ready_document_pdf":
        pdf_info = payload.get("ready_document_pdf", {})
        await handle_pdf_ready(pdf_info.get("document_id"), pdf_info.get("pdf_url"))

    return {"status": "ok"}
```

### Python (Flask)
```python
from flask import Flask, request, jsonify
import binascii
from ecdsa import VerifyingKey, NIST256p
from ecdsa.util import sigdecode_der

app = Flask(__name__)
EFORMSIGN_PUBLIC_KEY = "YOUR_PUBLIC_KEY_HEX"  # from Webhook settings

def verify_eformsign_signature(public_key_hex: str, signature_hex: str, body: bytes) -> bool:
    try:
        public_key_bytes = binascii.unhexlify(public_key_hex)
        vk = VerifyingKey.from_string(public_key_bytes, curve=NIST256p)
        signature_bytes = binascii.unhexlify(signature_hex)
        return vk.verify(signature_bytes, body, sigdecode=sigdecode_der)
    except Exception:
        return False

@app.post("/webhook/eformsign")
def handle_eformsign_webhook():
    body = request.get_data()  # raw bytes — required for signature verification

    signature = request.headers.get("eformsign_signature")
    if signature and not verify_eformsign_signature(EFORMSIGN_PUBLIC_KEY, signature, body):
        return jsonify({"error": "Invalid signature"}), 401

    payload = request.get_json(force=True)
    event_type = payload.get("event_type")

    if event_type == "document":
        document = payload.get("document", {})
        status = document.get("status")          # "status" not "document_status"
        doc_id = document.get("id")              # "id" not "document_id"
        outside_token = document.get("outside_token", "")

        if status == "doc_request_participant" and outside_token:
            pass  # store outside_token for external signing embedding
        elif status == "doc_complete":
            pass  # handle completed document

    elif event_type == "ready_document_pdf":
        pdf_info = payload.get("ready_document_pdf", {})
        pdf_url = pdf_info.get("pdf_url")

    return jsonify({"status": "ok"})

if __name__ == "__main__":
    app.run(port=5000)
```

### Node.js (Express)
```javascript
const express = require('express');
const app = express();
app.use(express.raw({ type: 'application/json' }));

const PUBLIC_KEY_HEX = 'YOUR_PUBLIC_KEY_HEX';

app.post('/webhook/eformsign', (req, res) => {
  const body = req.body;
  const signature = req.headers['eformsign_signature'];

  if (signature && !verifySignature(PUBLIC_KEY_HEX, signature, body)) {
    return res.status(401).json({ error: 'Invalid signature' });
  }

  const payload = JSON.parse(body.toString());
  const { event_type, document, ready_document_pdf } = payload;

  if (event_type === 'document') {
    const status = document.status;           // "status" not "document_status"
    const doc_id = document.id;              // "id" not "document_id"
    const outside_token = document.outside_token;

    if (status === 'doc_request_participant' && outside_token) {
      // Use outside_token as external_token in EformSignDocument embedding
      console.log(`External signing token for ${doc_id}: ${outside_token}`);
    } else if (status === 'doc_complete') {
      console.log(`Document completed: ${doc_id}`);
    }
  } else if (event_type === 'ready_document_pdf') {
    const { document_id, pdf_url } = ready_document_pdf;
    console.log(`PDF ready: ${document_id} — ${pdf_url}`);
  }

  res.json({ status: 'ok' });
});

app.listen(3000);
```
