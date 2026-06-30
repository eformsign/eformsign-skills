# eformsign Skill

eformsign 전자문서 서비스 연동 앱 개발을 돕는 **Agent Skill**입니다.  
공식 문서의 오류·누락·실제 서버 동작 차이를 보완하는 레퍼런스를 담고 있습니다.

[Agent Skills](https://agentskills.io) 오픈 표준을 따르며, Claude Code·Cursor·GitHub Copilot·Cline 등 다양한 AI 코딩 클라이언트에서 사용할 수 있습니다.

---

## 스킬 종류

| 스킬 | 대상 | 포함 기능 |
|------|------|-----------|
| `eformsign` | 관리자 / 풀스택 개발자 | API(문서+조직관리)+임베딩+Webhook+MCP |
| `eformsign-user` | 일반 앱 개발자 | API(문서)+임베딩+Webhook (조직관리 제외) |

---

## 지원 클라이언트

| 클라이언트 | 자동 호출 | 설치 경로 |
|-----------|----------|-----------|
| **Claude Code** | ✅ | `~/.claude/skills/` |
| **Claude Desktop + claude.ai** | ✅ | UI 업로드 (계정 동기화) |
| **Cursor** | ✅ | `~/.cursor/skills/` |
| **GitHub Copilot** (VS Code) | ✅ | `~/.copilot/skills/` |
| **Cline** (VS Code) | ✅ | `~/.cline/skills/` |
| **Google Antigravity** (+ `agy` CLI) | ✅ | `~/.gemini/config/skills/` |
| **Codex CLI** (`codex`) | ✅ | `~/.codex/skills/` |
| **ChatGPT** (웹/앱) | — | Business+ 플랜 필요 |

자세한 설치 방법은 **[INSTALL.ko.md](INSTALL.ko.md)** (한국어) 또는 **[INSTALL.md](INSTALL.md)** (영어)를 참고하세요.

---

## 스킬로 할 수 있는 것

### Open API 연동

| 작업 | 내용 |
|------|------|
| 인증 | Access Token 발급(Bearer / Basic / eformsign Signature), Refresh Token 갱신 |
| 문서 | 생성, 목록 조회, 상세 조회, PDF 다운로드, 삭제, 취소, 반려, 대량 전송 |
| 조직 관리 | 템플릿 목록 조회, 멤버 추가·수정, 그룹 생성·수정, 회사 도장 관리 |
| 서명 생성 | SHA256withECDSA 서명 헤더(`eformsign_signature`) 생성 코드 (Python/JS/Java/PHP/C#) |

### Embedding (iframe 임베딩)

| 작업 | 내용 |
|------|------|
| 문서 작성 | 템플릿 기반 신규 문서 생성 화면 임베딩 |
| 문서 처리 | 수신자가 서명·결재하는 화면 임베딩 |
| 문서 미리보기 | 완성 문서 읽기 전용 뷰어 임베딩 |
| 외부 사용자 서명 | Webhook `outside_token` 연동 → 비회원 서명 흐름 구현 |
| 사전 입력(Prefill) | 필드값 자동 입력, 수신자 사전 지정, 문서 접근 인증 설정 |
| 콜백 처리 | `success_callback` / `error_callback` 구현, document_id 추출 후 PDF 다운로드 |

### Webhook 처리

| 작업 | 내용 |
|------|------|
| 이벤트 수신 | 문서 상태 변경(`document`), PDF 생성 완료(`ready_document_pdf`) 이벤트 처리 |
| 서명 검증 | `eformsign_signature` 헤더로 수신 요청 진위 확인 (NIST256p / ecdsa 라이브러리) |
| 서버 구현 | Flask(Python), Express(Node.js) 웹훅 수신 서버 예제 |

### 지원 언어

Python · JavaScript/Node.js · Java · PHP · C#

---

## 레퍼런스 파일 구성

```
eformsign/
├── SKILL.md                     # 스킬 진입점 — 레퍼런스 참조 안내
└── references/
    ├── api_auth.md              # 인증, 토큰 발급·갱신, 서명 생성
    ├── api_documents.md         # 문서 CRUD API
    ├── api_org.md               # 템플릿·멤버·그룹·도장 API
    ├── embedding_setup.md       # 스크립트 로딩, SDK 객체
    ├── embedding_config.md      # document_option 전체 구조
    ├── embedding_advanced.md    # 콜백, 고급 옵션, 전체 예제
    ├── webhook.md               # Webhook 이벤트, 검증, 서버 예제
    ├── code_examples.md         # 언어별 코드 예제
    ├── sdk_findings.md          # 공식 문서 오류·SDK 버그·서버 동작 차이
    └── mcp_findings.md          # MCP 툴 목록, 파라미터, REST API 대비 동작 차이
```

```
eformsign-user/
├── SKILL.md                     # 일반 사용자용 스킬 진입점
└── references/
    ├── api_auth.md
    ├── api_documents.md         # api_org.md 제외 (조직 관리 불필요)
    ├── embedding_setup.md
    ├── embedding_config.md
    ├── embedding_advanced.md
    ├── webhook.md
    ├── code_examples.md
    ├── sdk_findings.md
    └── mcp_findings.md          # MCP member 툴 동작 참조
```

---

## 패키징

```bash
# skill-creator 디렉토리에서 실행 (위치: ~/.claude/skills/skill-creator/)
cd "C:\Users\{username}\.claude\skills\skill-creator"

# eformsign (전체 기능)
PYTHONUTF8=1 PYTHONIOENCODING=utf-8 python -m scripts.package_skill "path/to/eformsign" "output/dir"

# eformsign-user (일반 사용자 기능)
PYTHONUTF8=1 PYTHONIOENCODING=utf-8 python -m scripts.package_skill "path/to/eformsign-user" "output/dir"
```

성공 시 출력 디렉토리에 `eformsign.skill`, `eformsign-user.skill` 파일이 생성됩니다.

> **Windows 인코딩 주의**: `PYTHONUTF8=1 PYTHONIOENCODING=utf-8` 없이 실행하면 한글 처리 오류가 발생합니다.
