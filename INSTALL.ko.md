# eformsign Skill — 설치 가이드

## 이 스킬이란?

[eformsign](https://www.eformsign.com) 전자문서 서비스 연동 개발을 도와주는 **Agent Skill**입니다. REST API, iframe 임베딩, Webhook, MCP 툴에 대한 정확한 레퍼런스를 제공하며, 공식 문서에 없는 실제 서버 동작 차이와 미기재 필수 필드 정보를 포함합니다.

Agent Skills는 오픈 표준으로, Claude Code와 Cursor 등 여러 AI 코딩 클라이언트에서 사용할 수 있습니다.

---

## 어떤 스킬을 설치할까요?

| 스킬 파일 | 대상 | 포함 기능 |
|-----------|------|-----------|
| `eformsign.skill` | 관리자 / 풀스택 개발자 | 문서 API 전체 + 조직 관리(템플릿·멤버·그룹·도장) + 임베딩 + Webhook + MCP(관리자) |
| `eformsign-user.skill` | 일반 앱 개발자 | 문서 API + 임베딩 + Webhook + MCP(멤버) — 조직 관리 제외 |

**잘 모르겠다면** `eformsign-user.skill`을 먼저 설치하세요. 템플릿·멤버 관리가 필요하면 나중에 `eformsign.skill`을 추가하면 됩니다.

---

## 지원 클라이언트

| 클라이언트 | 테스트 | 글로벌 설치 경로 |
|-----------|--------|-----------------|
| **Claude Code** | ✅ | `~/.claude/skills/` |
| **Claude Desktop + claude.ai** | ✅ | UI 기반 (설정 > 사용자 지정 > 스킬) |
| **Cursor** | ✅ | `~/.cursor/skills/` |
| **GitHub Copilot** (VS Code) | ✅ | `~/.copilot/skills/` |
| **Google Antigravity** (데스크탑 + `agy` CLI) | ✅ | `~/.gemini/config/skills/` |
| **Codex CLI** (`codex`) | ✅ | `~/.codex/skills/` |
| **Cline** (VS Code) | ✅ | `~/.cline/skills/` |
| **ChatGPT** (웹/앱) | ❌ Business 이상 플랜 필요 | UI 기반, 파일 시스템 불가 |

> **팁:** GitHub Copilot은 `~/.claude/skills/`도 스킬 경로로 인식합니다. Claude Code용으로 이미 설치했다면 별도 설치 없이 GitHub Copilot에서도 자동으로 로드될 수 있습니다.

---

## 설치

이 저장소의 [`dist/`](dist/) 폴더에서 `.skill` 파일을 다운로드하세요.

### Claude Code

#### macOS / Linux

```bash
mkdir -p ~/.claude/skills
cd ~/.claude/skills
unzip /경로/eformsign.skill
```

#### Windows (PowerShell)

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\skills"
cd "$env:USERPROFILE\.claude\skills"
Expand-Archive -Force "C:\경로\eformsign.skill" .
```

설치 후 **새 Claude Code 세션을 시작**하세요 — 스킬은 세션 시작 시 로드됩니다.

---

### Claude Desktop + claude.ai

1. **설정 > 사용자 지정 > 스킬 > 추가 > 스킬 만들기 > 스킬 업로드** 열기
2. [`dist/`](dist/) 폴더의 `.skill` 파일 선택
3. 확인 — 스킬 이름과 설명이 자동으로 표시됨

파일 경로 설정 불필요. 대화 내용에 따라 자동으로 스킬이 호출됩니다. Free, Plus, Pro, Max 플랜 모두 지원.

> **스킬은 Anthropic 계정에 연동되어 동기화됩니다** — Claude Desktop에서 설치한 스킬은 claude.ai에서도 자동으로 사용 가능하고, 반대의 경우도 동일합니다. 한 번 설치로 두 곳 모두 적용됩니다.

---

### GitHub Copilot (VS Code)

#### macOS / Linux

```bash
mkdir -p ~/.copilot/skills
cd ~/.copilot/skills
unzip /경로/eformsign.skill
```

#### Windows (PowerShell)

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.copilot\skills"
cd "$env:USERPROFILE\.copilot\skills"
Expand-Archive -Force "C:\경로\eformsign.skill" .
```

> **Claude Code 이미 설치했다면?** 이 단계를 건너뛰어도 됩니다. GitHub Copilot은 `~/.claude/skills/`도 스캔하므로 이미 설치된 스킬이 함께 동작합니다.

경로를 추가하려면 VS Code 설정에서 `chat.agentSkillsLocations`에 원하는 경로를 추가하세요.

설치 후 **VS Code를 새로고침**하거나 새 Copilot Chat 세션을 여세요.

---

### Cursor

#### macOS / Linux

```bash
mkdir -p ~/.cursor/skills
cd ~/.cursor/skills
unzip /경로/eformsign.skill
```

#### Windows (PowerShell)

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.cursor\skills"
cd "$env:USERPROFILE\.cursor\skills"
Expand-Archive -Force "C:\경로\eformsign.skill" .
```

> **⚠️ 주의:** `~/.cursor/skills-cursor/` 경로에 파일을 넣으면 **안 됩니다**. 이 디렉토리는 Cursor 내부 전용으로 자동 관리되며, 여기에 넣은 사용자 스킬은 무시되거나 덮어씌워집니다.

설치 후 **Cursor를 재시작**하세요 — 스킬은 시작 시 로드됩니다.

---

### Google Antigravity (데스크탑 + `agy` CLI)

#### macOS / Linux

```bash
mkdir -p ~/.gemini/config/skills
cd ~/.gemini/config/skills
unzip /경로/eformsign.skill
```

#### Windows (PowerShell)

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.gemini\config\skills"
cd "$env:USERPROFILE\.gemini\config\skills"
Expand-Archive -Force "C:\경로\eformsign.skill" .
```

설치 후 Antigravity를 재시작하거나 새 세션을 여세요. 별도 호출 없이 자동으로 스킬이 로드됩니다.

---

### Codex CLI

#### macOS / Linux

```bash
mkdir -p ~/.codex/skills
cd ~/.codex/skills
unzip /경로/eformsign.skill
```

#### Windows (PowerShell)

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.codex\skills"
cd "$env:USERPROFILE\.codex\skills"
Expand-Archive -Force "C:\경로\eformsign.skill" .
```

> `~/.codex/skills/`에 설치하면 Codex 데스크탑 앱과 IDE 확장에서도 동일하게 사용할 수 있습니다. 한 번 설치로 모든 Codex 환경에 적용됩니다.

설치 후 새 `codex` 세션을 시작하세요.

---

### Cline (VS Code)

#### macOS / Linux

```bash
mkdir -p ~/.cline/skills
cd ~/.cline/skills
unzip /경로/eformsign.skill
```

#### Windows (PowerShell)

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.cline\skills"
cd "$env:USERPROFILE\.cline\skills"
Expand-Archive -Force "C:\경로\eformsign.skill" .
```

설치 후 VS Code의 Cline 패널 하단 **⚖️ 아이콘**을 클릭하고 Skills 탭에서 eformsign 스킬이 활성화되어 있는지 확인하세요.

---

### 공통 (Python 스크립트)

```python
import zipfile, os

skill_file = "eformsign.skill"   # 또는 eformsign-user.skill

# 클라이언트에 맞게 경로 변경:
#   Claude Code        → os.path.join(os.path.expanduser("~"), ".claude", "skills")
#   Cursor             → os.path.join(os.path.expanduser("~"), ".cursor", "skills")
#   GitHub Copilot     → os.path.join(os.path.expanduser("~"), ".copilot", "skills")
#   Google Antigravity → os.path.join(os.path.expanduser("~"), ".gemini", "config", "skills")
#   Codex CLI          → os.path.join(os.path.expanduser("~"), ".codex", "skills")
#   Cline              → os.path.join(os.path.expanduser("~"), ".cline", "skills")
install_dir = os.path.join(os.path.expanduser("~"), ".claude", "skills")

os.makedirs(install_dir, exist_ok=True)
with zipfile.ZipFile(skill_file, "r") as z:
    z.extractall(install_dir)

print(f"설치 완료: {install_dir}")
```

---

## 설치 확인 및 사용

### Claude Code

새 세션에서 eformsign 관련 작업을 요청하면 자동으로 스킬이 로드됩니다:

```
eformsign signature 방식으로 access token을 발급하는 Python 코드를 작성해줘.
```

스킬 로드 여부를 직접 확인하려면:
```
사용 가능한 eformsign 스킬이 있나요?
```

### Claude Desktop + claude.ai

eformsign 관련 작업을 요청하면 두 환경 모두에서 자동으로 스킬이 로드됩니다:

```
eformsign signature 방식으로 access token을 발급하는 Python 코드를 작성해줘.
```

### GitHub Copilot (VS Code)

VS Code의 **Copilot Chat**을 **Agent 모드**로 열고 `/`로 스킬을 호출하세요:

```
/eformsign eformsign API로 문서를 생성하는 Python 코드 작성해줘
```

> 입력창에 `/`를 치면 사용 가능한 스킬 목록이 표시됩니다. `eformsign`을 선택하거나 직접 입력하세요.

### Cursor

**Agent 모드** (`Ctrl+I` / `Cmd+I`)를 열고 작업을 설명하면 자동으로 스킬이 로드됩니다:

```
eformsign API로 access token 발급하는 Python 코드 작성해줘
```

명시적으로 호출하려면 `@`를 붙이세요:

```
@eformsign 외부 사용자 서명 임베딩 방법 알려줘
```

### Cline (VS Code)

eformsign 관련 작업을 요청하면 자동으로 스킬이 로드됩니다:

```
eformsign signature 방식으로 access token을 발급하는 Python 코드를 작성해줘.
```

### Google Antigravity

**데스크탑 앱:** eformsign 관련 작업을 요청하면 자동으로 스킬이 로드됩니다:

```
eformsign signature 방식으로 access token을 발급하는 Python 코드를 작성해줘.
```

**CLI (`agy`):** 터미널에서도 동일하게 동작합니다:

```bash
agy "eformsign signature 방식으로 access token을 발급하는 Python 코드를 작성해줘."
```

또는 인터랙티브 모드:

```bash
agy
```

---

## 사용 예시 프롬프트

**API 연동:**
```
eformsign signature 방식으로 access token을 발급하는 Python 코드를 작성해줘.
```

**임베딩:**
```
외부 사용자(비회원)가 서명할 수 있도록 eformsign 문서 서명 화면을 React에 임베딩하는 방법을 알려줘.
```

**Webhook:**
```
eformsign webhook 이벤트를 수신하고 서명을 검증하는 Node.js Express 서버를 만들어줘.
```

**문서 처리:**
```
eformsign API로 문서를 생성하고, 완료 후 PDF를 다운로드하는 전체 흐름을 보여줘.
```

---

## 클라이언트별 차이점

| | Claude Code | Claude Desktop / claude.ai | GitHub Copilot | Cursor | Cline | Google Antigravity | Codex CLI |
|--|-------------|---------------------------|----------------|--------|-------|--------------------|-----------|
| 설치 경로 | `~/.claude/skills/` | UI 업로드 (계정 동기화) | `~/.copilot/skills/` | `~/.cursor/skills/` | `~/.cline/skills/` | `~/.gemini/config/skills/` | `~/.codex/skills/` |
| 추가 스캔 경로 | — | — | `~/.claude/skills/` ✓ | — | — | — | — |
| 프로젝트 경로 | `.claude/skills/` | — | `.github/skills/` | `.cursor/skills/` | `.cline/skills/` | `.agents/skills/` | `.codex/skills/` |
| 자동 호출 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ (시맨틱 매칭) | ✅ |
| 명시적 호출 | — | — | ✅ `/eformsign` | `@eformsign` | — | — | — |
| CLI 지원 | ✅ | — | — | — | — | ✅ `agy` | ✅ `codex` |
| `disable-model-invocation` | 미지원 | 미지원 | 지원 | 지원 | 미확인 | 미확인 | 미확인 |
| 비고 | — | Free/Plus/Pro/Max; Desktop ↔ claude.ai 동기화 | description이 쿼리 의도와 충분히 넓게 매칭되어야 자동 호출 작동 | — | ⚖️ 아이콘 → Skills 탭에서 활성화 | 퍼블릭 프리뷰 무료 | Codex 앱·IDE 확장과 경로 공유 |
| 추가 설정 | — | — | `chat.agentSkillsLocations` (VS Code 설정) | — | — | — | — |

### `disable-model-invocation`이란?

Cursor 전용 SKILL.md 프론트매터 필드로, 스킬 호출 방식을 제어합니다:

| 값 | 동작 |
|----|------|
| 없음 (기본) | AI가 작업 내용을 보고 관련 있다고 판단하면 자동으로 스킬 로드 |
| `true` | AI 자동 선택 비활성화 — `@eformsign`처럼 명시적으로 호출해야만 작동 |

Cursor는 스킬이 많을 때 불필요한 로딩을 막기 위해 기본적으로 `true`를 권장합니다. eformsign 스킬은 이 필드를 설정하지 않으므로 자동 호출로 동작합니다 (Claude Code와 동일). 원하지 않는 상황에 스킬이 자동으로 로드된다면 SKILL.md 프론트매터에 `disable-model-invocation: true`를 추가하면 됩니다.

---

## 스킬이 커버하는 영역

| 영역 | 내용 |
|------|------|
| **인증** | Access Token 발급 (Bearer / Basic / eformsign Signature), Refresh Token 갱신 |
| **문서 API** | 생성, 목록 조회, 상세 조회, PDF 다운로드, 삭제, 취소, 반려, 대량 발송, 재전송 |
| **조직 관리** | 템플릿, 멤버, 그룹, 회사 도장 (`eformsign.skill` 전용) |
| **임베딩** | 스크립트 로딩, `EformSignDocument`/`EformSignTemplate` SDK, `document_option` 전체 구조, 콜백 |
| **Webhook** | 이벤트 구조, 서명 검증, 서버 예제 (Python/Node.js) |
| **MCP** | 툴 목록, 파라미터, REST API 대비 동작 차이 |
| **코드 예제** | Python, JavaScript/Node.js, Java, PHP, C# 언어별 예제 |

### 문서화된 알려진 이슈

| ID | 분류 | 내용 |
|----|------|------|
| BUG-01 | API 경로 오류 | `GET /api/list_documents` (복수) → 실제는 `/api/list_document` (단수) 사용 |
| BUG-02 | 서버 동작 차이 | `limit` 필드가 선택 사항으로 문서화되어 있으나 생략 시 빈 목록 반환 |
| BUG-03 | SDK 버그 | `efs_embedded_v2.js`와 `efs_embedded_form.js` 동시 로드 시 전역 상수 충돌 |
| BUG-04 | 서버 동작 차이 | `PATCH /api/members`: `account.contact` 실제 필수 (에러 4000070) |
| BUG-05 | SDK 미기재 필드 | `user.auth_id` 미기재 필수 필드 — 누락 시 외부 서명자가 로그인 페이지로 이동 |
| BUG-06 | 서버 동작 차이 | `PATCH /api/groups`: `group.description` 실제 필수 (에러 4000001) |

---

## 스킬 업데이트

최신 `.skill` 파일을 다운로드한 후 동일한 설치 과정을 반복하면 기존 버전을 덮어씁니다.

---

## 지원 언어

Python · JavaScript/Node.js · Java · PHP · C#
