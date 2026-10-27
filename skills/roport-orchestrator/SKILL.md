---
name: roport-orchestrator
description: "RO:PORT 모노레포(Pinky·OMX 로봇팔·관제 서버·AI 서버·서비스 서버·Web)의 기능 구현·연동·장애 수정을 분야별 엔지니어 에이전트에 나눠 맡기고 탐색→계약 설계→구현→안전 검토·QA 순서로 조율한다. 서비스↔관제 WSS, 로봇↔관제 MQTT, AI 추론 연동, 양팔 반출, Pinky 운송·도킹, 주문·작업 상태 흐름, API/schema 변경, '관제랑 웹 같이 고쳐줘', '로봇팔 실행 검사 구현해줘' 같은 요청에 사용한다. 다시 실행, 검토 지적 반영, 이전 결과 개선, '검토만 다시', 'QA만 다시', '웹 쪽만 다시' 같은 후속 요청에도 사용한다. 단일 파일 간단 수정·개념 질문에는 쓰지 않고, Pinky 내부 차선 인식·주행 알고리즘·Nav2 작업은 pinky-harness:pinky-robotics를 쓴다. 로봇 실물 조작 요청에는 쓰지 않는다."
---

# RO:PORT 개발 오케스트레이터

목표는 요청 기능의 코드·양쪽 인터페이스·검증 근거를 함께 완성하는 것이다. 이 스킬은 로봇·모델·Cloud를 구동할 권한을 주지 않는다.
제품 저장소(kernel-robot-repo-1) 루트에서 시작한 세션에서 실행한다. 이 하네스는 플러그인으로 설치되므로 팀의 추적 파일을 바꾸지 않는다.

## 팀 구성

| 에이전트 (`subagent_type`) | 모델 | 쓰기 | 역할 |
| --- | --- | --- | --- |
| `roport-harness:roport-explorer` | sonnet | 없음 | 모듈별 현황·인터페이스 수집 |
| `roport-harness:roport-architect` | opus | 없음 | 공용 계약·작업 분할·소유권 |
| `roport-harness:roport-reviewer` | opus | 없음 | diff 기반 계약·안전 판정 |
| `roport-harness:roport-qa` | sonnet | 없음 | CI 실행·경계 대조 |

모듈 구현은 분야별 엔지니어가 맡는다. 모두 [공통 규칙](references/engineer-rules.md)을 따른다.

| 모듈 | 엔지니어 (`subagent_type`) | 모델 |
| --- | --- | --- |
| `services/roport-pinky` | `roport-harness:pinky-engineer` | opus |
| `services/roport-omx` | `roport-harness:omx-arm-engineer` | opus |
| `services/roport-control-server` | `roport-harness:control-server-engineer` | opus |
| `services/roport-ai-server` | `roport-harness:ai-engineer` | opus |
| `services/roport-service-server` | `roport-harness:service-server-engineer` | opus |
| `services/roport-web` | `roport-harness:web-engineer` | sonnet |

Pinky 차선 인식·Pure Pursuit·Nav2 내부는 `pinky-harness` 플러그인 에이전트(`lane-perception-dev`, `drive-control-dev`, `nav2-dev`)에 맡긴다. 설치돼 있지 않으면 `pinky-engineer`가 처리하고 미설치 사실을 보고한다.
루트 파일(`scripts/`, `.github/`, 루트 `package.json`)과 부모 소유 파일은 메인이 직접 고친다. 필요한 역할만 실행한다.

## 0단계: 맥락 확인과 규모 판단

1. 루트·대상 모듈 `AGENTS.md`, `git status`/branch, 관련 manifest·CI를 읽는다.
2. 규모를 고른다.
   - **직접 처리**: 몇 줄·몇 파일의 단순 수정이면 에이전트 없이 고치고 해당 모듈 CI만 돌린다.
   - **단일 모듈**: 한 모듈 안의 기능·버그 수정이고 다른 모듈과의 계약이 바뀌지 않으면 1·2단계를 건너뛰고 해당 엔지니어 → QA로 진행한다. 안전 체크리스트(S) 항목에 닿으면 reviewer도 실행한다.
   - **여러 모듈**: 모듈 둘 이상이거나 모듈 간 계약이 바뀌면 아래 전 단계를 따른다.
3. 작업 디렉터리 `_workspace/claude/`를 쓴다. 쓰기 전에 `.git/info/exclude`에 `/_workspace/claude/`가 없으면 추가한다(로컬 전용, 팀 `.gitignore`는 건드리지 않는다).
4. 기존 결과 확인:
   - `_workspace/claude/`가 있고 부분 수정 요청이면 해당 단계만 다시 실행한다(예: "검토만 다시" → 4단계만).
   - 새 기능 요청이면 기존 디렉터리를 `_workspace/claude_<YYYYMMDD-HHMM>/`로 옮기고 새로 시작한다.
5. 연동·설계 변경이면 [프로젝트 맥락](references/project-context.md)을 읽고 관련 최신 Tech Spec·Jira를 확인한다. 접근이 막히면 미확인 범위로 남긴다.

## 1단계: 탐색

**실행 모드:** 서브에이전트 위임 (모듈마다 `roport-explorer` 1개, 한 메시지에서 병렬 호출)

- 각 호출에 요청 요약·대상 모듈을 넘기고, 반환 결과를 `_workspace/claude/01_explorer_<module>.md`로 저장한다.
- 영향 모듈이 이미 명확하고 2개 이하면 메인이 직접 읽고 이 단계를 생략해도 된다.

## 2단계: 계약 설계

**실행 모드:** 서브에이전트 위임 (`roport-architect` 1개)

- 결과를 `_workspace/claude/02_architect_contract.md`로 저장한다.
- `미정 결정`이 있으면 **사용자에게 묻고** 답을 계약 파일에 반영한 뒤 진행한다. 미정 값을 에이전트가 정하게 두지 않는다.
- 공유 schema·lockfile·공용 설정(`부모 소유`)은 메인이 먼저 반영한다.

## 3단계: 모듈별 구현

**실행 모드:** 지속형 에이전트 (예: `Agent(name: "control-server-engineer", subagent_type: "roport-harness:control-server-engineer")`)

- 작업 분할의 모듈에 맞는 엔지니어를 위 표에서 골라 그 이름 그대로 실행한다. 같은 모듈에 작업이 둘이면 `<engineer>-2`처럼 이름을 붙이고 소유 경로를 나눈다.
- 선행 관계가 없는 작업만 동시에 실행한다(최대 3개). 같은 파일·빌드 캐시를 쓰는 작업은 순차 실행한다.
- 작업 패킷: 작업 ID, 모듈, 소유 경로, 계약 경로, 완료 기준, 검증 명령, 동시에 작업 중인 다른 엔지니어 이름과 소유 경로.
- 엔지니어 질문(계약 해석·소유권 밖 수정)은 메인이 답하고, 계약을 바꾸면 계약 파일을 고친 뒤 관련 엔지니어 모두에게 `SendMessage`로 알린다.
- 지속형 에이전트를 쓸 수 없는 환경이면 같은 정의로 일반 서브에이전트를 호출하고, 수정 루프는 새 호출에 이전 보고서 경로를 넘기는 방식으로 대체한다. 대체 사실을 보고에 적는다.

## 4단계: 검토와 QA

**실행 모드:** 서브에이전트 위임 (`roport-reviewer` 1개 + 변경 모듈마다 `roport-qa`, 한 메시지에서 병렬 호출)

- 엔지니어가 끝나는 대로 그 모듈의 QA를 바로 시작한다. 리뷰어는 전체 diff가 모인 뒤 실행한다.
- 결과를 `04_reviewer_review.md`, `04_qa_<module>.md`로 저장한다.
- 판정 처리:
  - `FAIL` → 지적된 모듈의 엔지니어에게 `SendMessage`로 지적 파일 경로를 보내 고치게 하고 4단계를 다시 실행한다. **최대 2회**. 남은 실패는 보고서에 명시한다.
  - `BLOCKED` → 안전 항목 UNVERIFIED 목록을 사용자에게 보여 주고 판단을 받는다.
  - `PASS` + QA `PASS` → 5단계.

## 5단계: 통합 보고

- 실제 변경 파일, 계약 요약, 실행한 명령·결과, 미실행·남은 실패를 보고한다.
- 정적 검사 / mock·단위 테스트 / 시뮬레이션 / 실장비 / Cloud를 구분한다. 원격 push·CI는 직접 조회한 결과만 적는다.
- 커밋은 사용자가 지시할 때만, `[FFT1-번호] type: 제목` 형식과 실제 Jira 번호로 한다.

## 데이터 전달

| 단계 | 방식 | 위치 |
| --- | --- | --- |
| 1→2 | 반환값 → 파일 | `_workspace/claude/01_explorer_<module>.md` |
| 2→3 | 파일 | `_workspace/claude/02_architect_contract.md` |
| 3→4 | 파일 + git diff | `_workspace/claude/03_<engineer>_report.md` |
| 4→3 | `SendMessage` + 파일 | `_workspace/claude/04_*.md` |

읽기 전용 에이전트는 파일을 쓸 수 없으므로 반환값을 메인이 저장한다.

## 오류 처리

- 에이전트 실패는 한 번 다시 시도한다. 또 실패하면 그 결과 없이 진행하고 누락을 보고한다.
- 사용량 한도·인증 만료·권한 거부는 재시도하지 않는다. `_workspace/claude/`의 부분 산출물로 진행 범위를 확인해 기록하고 사용자에게 알린다(한도면 해제 시각 포함).
- 응답 없는 엔지니어는 `SendMessage`로 상태를 묻고, 그래도 안 되면 같은 유형을 새 이름으로 실행하며 이전 보고서 경로를 넘긴다. 소유 경로는 이전 엔지니어 중단을 확인한 뒤 넘긴다.
- 멈춘 에이전트의 빈칸은 메인이 직접 확인한 사실로만 채운다. 판단을 추측해 채우지 않는다.
- 탐색·계약과 코드가 충돌하면 지우지 말고 출처와 함께 남긴다.

## 테스트 시나리오

**정상 흐름** — "관제 서버에 작업 상태 조회 API를 추가하고 어드민 웹에 표시해줘"
1. 0단계: 두 모듈 → 하네스 실행, `_workspace/claude/` 생성.
2. 1단계: explorer ×2(control-server, web) 병렬.
3. 2단계: architect가 응답 schema·상태 enum·오류 응답을 정의, `미정` 없음.
4. 3단계: `control-server-engineer`, `web-engineer` 병렬(소유 경로 분리).
5. 4단계: QA ×2 + reviewer → PASS.
6. 5단계: 변경·명령·결과 보고, 실장비 검증 없음 명시.

**단일 모듈 흐름** — "OMX 실행 검사에서 deadline 지난 action을 버리게 해줘"
1. 0단계: 단일 모듈, 안전 항목(S3) 관련 → 1·2단계 생략.
2. 3단계: `omx-arm-engineer` 1명.
3. 4단계: QA(omx) + reviewer.

**오류 흐름** — "로봇 명령 MQTT 재전송 처리를 관제와 Pinky에 추가"
1. 2단계에서 command 만료 시간이 `미정` → 사용자에게 질문 후 계약 반영.
2. 3단계: `control-server-engineer`, `pinky-engineer` 병렬.
3. 4단계 reviewer `FAIL`(Pinky에서 중복 command ID가 재구동됨) → `pinky-engineer`에 지적 전달, 수정 후 재검토 PASS.
4. Pinky CI는 ROS 미설치로 colcon `미실행` → 통과로 숨기지 않고 보고.
