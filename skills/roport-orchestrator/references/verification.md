# 검증 실행

명령의 원본은 제품의 `.github/workflows/<module>-ci.yml`이다. 이 문서는 요약이며, 다르면 워크플로를 따른다.
`rtk`가 있으면 셸 명령 앞에 `rtk` 또는 `rtk proxy`를 붙인다.

## 모듈 CI (2026-10-27 워크플로 기준)

| 모듈 | 디렉터리 | 명령 |
| --- | --- | --- |
| pinky | `services/roport-pinky` | ROS 2 Jazzy source 후 `bash ci/test.sh` |
| omx | `services/roport-omx` | `uv sync --locked` → `uv run ruff check src` → `uv run ruff format --check src` → `uv run python -c "import roport_omx"` → `bash ci/test.sh` → `uv build` |
| control-server / ai-server | `services/roport-<name>` | `uv sync --locked` → `uv run ruff check .` → `uv run ruff format --check .` → `uv run pytest` → `uv build` |
| service-server | `services/roport-service-server` | `mvn --batch-mode --no-transfer-progress verify` (Java 21, localhost 테스트 서버를 연다) |
| web | `services/roport-web` | `npm ci` → `npm run typecheck` → `npm run build` (Node.js 24) |

공통: 루트 `npm run test:commit`. 의존성 설치·빌드 캐시가 생길 수 있다. 장비 bringup·네트워크 배포는 추가하지 않는다.
Pinky·OMX의 `ci/test_*.py`는 표준 라이브러리만으로 `python3 -m unittest discover -s services/roport-<m>/ci -p 'test_*.py'`로 빠르게 돌릴 수 있다.

## 모듈 경계 대조

생산자·소비자에 같은 schema·단위·ID·시간 기준·오류 표현이 적용됐는지 본다.

1. 생산자 테스트의 fixture나 mock 응답을 소비자 파서/모델(Pydantic, TS 타입, Java DTO)에 넣어 본다.
2. 변경 범위에 맞게 정상, 중복 ID, 유실, 순서 역전, 만료, timeout, 재접속, 중도 재시작을 mock/replay로 확인한다.
3. 실제 토픽 publish·장비 connect·Cloud 호출로 검증하지 않는다.

## 보고 규칙

- 대상 commit 또는 로컬 diff, 환경, 실제 명령과 결과, 실패·미실행 사유를 남긴다.
- 미설치 도구·네트워크 차단은 통과가 아니라 `미실행`이다.
- 시뮬레이션·실장비 검증은 별도 절차이며 사용자 지시와 현장 안전 조건 확인 없이 하지 않는다.
