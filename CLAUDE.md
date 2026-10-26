# RO:PORT Claude Harness

이 저장소는 Claude Code 플러그인이다. 하네스 구조를 바꾸면 `bash scripts/check.sh`를 실행한다. 한국어로 작성한다.

## 하네스: RO:PORT 여러 모듈 개발

**목표:** Pinky·OMX·관제·AI·서비스·Web에 걸친 기능을 계약·구현·검증 근거와 함께 완성한다.

**호출 조건:** RO:PORT 제품 저장소에서 여러 모듈 구현·연동·수정과 그 후속 작업을 요청받으면 `roport-orchestrator` 스킬을 사용한다. 단순 질문과 단일 파일 수정은 직접 처리한다.

**변경 이력:**
| 날짜 | 변경 내용 | 대상 | 사유 |
| --- | --- | --- | --- |
| 2026-10-27 | Harness v2로 처음 구성 (Codex 하네스의 5개 역할을 Claude 플러그인으로 이식) | 전체 | 팀 저장소와 분리된 개인 Claude 하네스 필요 |
