# RO:PORT Claude Harness

RO:PORT 모노레포의 여러 모듈 개발을 돕는 개인 Claude Code 하네스(플러그인)입니다.
Codex 하네스는 [roport-codex-harness](https://github.com/jsh0116/roport-codex-harness)에서 따로 관리합니다.

## 구성

- `agents/` 공통 역할: `roport-explorer`(sonnet), `roport-architect`(opus), `roport-reviewer`(opus), `roport-qa`(sonnet)
- `agents/` 모듈 엔지니어: `pinky-engineer`, `omx-arm-engineer`, `control-server-engineer`, `ai-engineer`, `service-server-engineer`(opus), `web-engineer`(sonnet)
- `skills/roport-orchestrator/`: 탐색 → 계약 설계 → 모듈별 구현 → 검토·QA 흐름, 프로젝트 맥락·엔지니어 공통 규칙·검증·체크리스트
- `scripts/check.sh`: 하네스 자체 정합성 검사

Pinky 내부 차선 인식·주행·Nav2는 `pinky-harness` 플러그인을 사용합니다.

## 설치

플러그인으로 설치하므로 제품 저장소의 파일은 바뀌지 않습니다. 실행 중간 산출물만 제품의 `_workspace/claude/`에 쌓이며 `.git/info/exclude`로 로컬에서 제외합니다.

```text
/plugin marketplace add /absolute/path/to/roport-claude-harness
/plugin install roport-harness@roport-harness-marketplace
```

제품 저장소 루트에서 Claude Code를 열고 요청합니다.

```text
관제 서버에 작업 상태 조회 API를 추가하고 어드민 웹에 표시해줘
/roport-harness:roport-orchestrator 검토만 다시 해줘
```

## 개발

```bash
bash scripts/check.sh
```

수정 후에는 `/plugin` 메뉴에서 플러그인을 다시 불러옵니다. 프로젝트 사실의 원본은 제품 저장소와 최신 Confluence Tech Spec입니다.
