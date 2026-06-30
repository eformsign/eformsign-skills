# eformsign Code Examples by Language

## Table of Contents
1. [Signature Generation](#signature-generation)
2. [Full Access Token Flow](#full-access-token-flow)
3. [Create Document](#create-document)
4. [List & Download Documents](#list--download-documents)

---

## Signature Generation

Required when using eformsign Signature authentication for Access Token issuance or Webhook verification.

### Python
```python
# pip install ecdsa
import time
import binascii
from ecdsa import SigningKey, NIST256p

def generate_eformsign_signature(private_key_hex: str) -> tuple[str, int]:
    """
    Generate an eformsign signature.

    Args:
        private_key_hex: Private key issued with the API key (hex string)

    Returns:
        (signature_hex, execution_time_ms)
    """
    execution_time = int(time.time() * 1000)  # 13-digit millisecond timestamp
    message = str(execution_time).encode('utf-8')

    private_key_bytes = binascii.unhexlify(private_key_hex)
    sk = SigningKey.from_string(private_key_bytes, curve=NIST256p)
    signature = sk.sign(message)
    signature_hex = binascii.hexlify(signature).decode('utf-8')

    return signature_hex, execution_time
```

### JavaScript (Node.js)
```javascript
const crypto = require('crypto');

function generateEformsignSignature(privateKeyPem) {
  const executionTime = Date.now();
  const sign = crypto.createSign('SHA256');
  sign.update(Buffer.from(String(executionTime), 'utf-8'));
  sign.end();

  const signature = sign.sign({
    key: privateKeyPem,
    dsaEncoding: 'der'
  });

  return {
    signature: signature.toString('hex'),
    executionTime
  };
}

// Usage
const privateKeyPem = `-----BEGIN EC PRIVATE KEY-----
...
-----END EC PRIVATE KEY-----`;

const { signature, executionTime } = generateEformsignSignature(privateKeyPem);
```

### Java
```java
// No external dependencies required — uses standard JDK only.
// The private key hex must be PKCS#8 DER encoded (the format eformsign provides).
import java.security.*;
import java.security.spec.PKCS8EncodedKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.HexFormat;

public class EformsignSignature {

    public static SignatureResult generateSignature(String privateKeyHex) throws Exception {
        long executionTime = System.currentTimeMillis();
        byte[] message = String.valueOf(executionTime).getBytes(StandardCharsets.UTF_8);

        byte[] privateKeyBytes = HexFormat.of().parseHex(privateKeyHex);
        KeyFactory kf = KeyFactory.getInstance("EC");
        PrivateKey privateKey = kf.generatePrivate(new PKCS8EncodedKeySpec(privateKeyBytes));

        Signature sig = Signature.getInstance("SHA256withECDSA");
        sig.initSign(privateKey);
        sig.update(message);
        byte[] signatureBytes = sig.sign();

        return new SignatureResult(HexFormat.of().formatHex(signatureBytes), executionTime);
    }

    public record SignatureResult(String signatureHex, long executionTime) {}
}
```

### PHP
```php
function generateEformsignSignature(string $privateKeyPem): array {
    $executionTime = (int)(microtime(true) * 1000);
    $message = (string)$executionTime;

    $privateKey = openssl_pkey_get_private($privateKeyPem);
    openssl_sign($message, $signature, $privateKey, OPENSSL_ALGO_SHA256);

    return [
        'signature' => bin2hex($signature),
        'execution_time' => $executionTime
    ];
}
```

### C# (.NET)
```csharp
using System.Security.Cryptography;
using System.Text;

public static (string signature, long executionTime) GenerateSignature(byte[] privateKeyBytes)
{
    long executionTime = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
    byte[] message = Encoding.UTF8.GetBytes(executionTime.ToString());

    using var ecdsa = ECDsa.Create();
    ecdsa.ImportECPrivateKey(privateKeyBytes, out _);

    byte[] signatureBytes = ecdsa.SignData(message, HashAlgorithmName.SHA256);
    string signatureHex = BitConverter.ToString(signatureBytes).Replace("-", "").ToLower();

    return (signatureHex, executionTime);
}
```

---

## Full Access Token Flow

### Python (requests)
```python
import time
import requests
import binascii
from ecdsa import SigningKey, NIST256p

class EformsignClient:
    def __init__(self, private_key_hex: str, member_id: str):
        self.private_key_hex = private_key_hex
        self.member_id = member_id
        self.api_url = None
        self.access_token = None
        self.refresh_token = None

    def _generate_signature(self) -> tuple[str, int]:
        execution_time = int(time.time() * 1000)
        message = str(execution_time).encode('utf-8')
        sk = SigningKey.from_string(binascii.unhexlify(self.private_key_hex), curve=NIST256p)
        signature_hex = binascii.hexlify(sk.sign(message)).decode('utf-8')
        return signature_hex, execution_time

    def get_access_token(self, base_url: str = "https://kr-api.eformsign.com") -> dict:
        signature, execution_time = self._generate_signature()
        res = requests.post(
            f"{base_url}/api/auth/access_token",
            headers={"eformsign_signature": signature, "Content-Type": "application/json"},
            json={"execution_time": execution_time, "member_id": self.member_id}
        )
        res.raise_for_status()
        data = res.json()
        self.api_url = data["api_key"]["company"]["api_url"]
        self.access_token = data["oauth_token"]["access_token"]
        self.refresh_token = data["oauth_token"]["refresh_token"]
        return data

    def refresh_access_token(self) -> dict:
        res = requests.post(
            f"{self.api_url}/api/auth/refresh_token",
            headers={"Authorization": f"Bearer {self.access_token}", "Content-Type": "application/json"},
            json={"refresh_token": self.refresh_token}
        )
        res.raise_for_status()
        data = res.json()
        self.access_token = data["oauth_token"]["access_token"]
        self.refresh_token = data["oauth_token"]["refresh_token"]
        return data

    @property
    def headers(self) -> dict:
        return {"Authorization": f"Bearer {self.access_token}", "Content-Type": "application/json"}
```

### JavaScript (Node.js, axios)
```javascript
const axios = require('axios');
const crypto = require('crypto');

class EformsignClient {
  constructor(privateKeyPem, memberId) {
    this.privateKeyPem = privateKeyPem;
    this.memberId = memberId;
    this.apiUrl = null;
    this.accessToken = null;
    this.refreshToken = null;
  }

  _generateSignature() {
    const executionTime = Date.now();
    const sign = crypto.createSign('SHA256');
    sign.update(Buffer.from(String(executionTime), 'utf-8'));
    const signature = sign.sign({ key: this.privateKeyPem, dsaEncoding: 'der' });
    return { signature: signature.toString('hex'), executionTime };
  }

  async getAccessToken(baseUrl = 'https://kr-api.eformsign.com') {
    const { signature, executionTime } = this._generateSignature();
    const res = await axios.post(`${baseUrl}/api/auth/access_token`,
      { execution_time: executionTime, member_id: this.memberId },
      { headers: { 'eformsign_signature': signature, 'Content-Type': 'application/json' } }
    );
    this.apiUrl = res.data.api_key.company.api_url;
    this.accessToken = res.data.oauth_token.access_token;
    this.refreshToken = res.data.oauth_token.refresh_token;
    return res.data;
  }

  get headers() {
    return { Authorization: `Bearer ${this.accessToken}`, 'Content-Type': 'application/json' };
  }
}
```

---

## Create Document

### Python — create and send a document
```python
def create_document(client: EformsignClient, template_id: str, recipient_email: str, fields: dict) -> dict:
    """Send a document creation request to a recipient."""
    payload = {
        "document": {
            "document_name": "Contract",
            "comment": "Please review and sign this document.",
            "fields": [{"id": k, "value": v} for k, v in fields.items()],
            "recipients": [
                {
                    "step_type": "05",
                    "use_mail": True,
                    "use_sms": False,
                    "member": {"name": "Recipient", "id": recipient_email},
                    "auth": {"valid": {"day": 7, "hour": 0}}
                }
            ]
        }
    }
    res = requests.post(
        f"{client.api_url}/api/documents",
        params={"template_id": template_id},
        headers=client.headers,
        json=payload
    )
    res.raise_for_status()
    return res.json()

# Usage
data = create_document(
    client=client,
    template_id="YOUR_TEMPLATE_ID",
    recipient_email="recipient@example.com",
    fields={"CustomerName": "John Doe", "ContractAmount": "$1,000"}
)
print("Created document ID:", data.get("document_id"))
```

---

## List & Download Documents

### Python — download a completed document as PDF
```python
def download_document_pdf(client: EformsignClient, document_id: str, save_path: str) -> None:
    """Download a completed document as a PDF."""
    res = requests.get(
        f"{client.api_url}/api/documents/{document_id}/pdf",
        headers=client.headers,
        stream=True
    )
    res.raise_for_status()
    with open(save_path, 'wb') as f:
        for chunk in res.iter_content(chunk_size=8192):
            f.write(chunk)
    print(f"PDF saved: {save_path}")

def list_completed_documents(client: EformsignClient, template_id: str = None) -> dict:
    """List completed documents."""
    params = {"document_status": "doc_complete", "per_page": 50}
    if template_id:
        params["template_id"] = template_id
    res = requests.get(f"{client.api_url}/api/documents", headers=client.headers, params=params)
    res.raise_for_status()
    return res.json()
```

### JavaScript (Node.js) — list documents
```javascript
async function listDocuments(client, options = {}) {
  const params = new URLSearchParams({ per_page: 20, ...options });
  const res = await axios.get(`${client.apiUrl}/api/documents?${params}`, {
    headers: client.headers
  });
  return res.data;
}

// Usage
const docs = await listDocuments(client, {
  document_status: 'doc_complete',
  template_id: 'YOUR_TEMPLATE_ID'
});
console.log(`Total completed documents: ${docs.total_count}`);
```
