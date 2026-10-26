# 프로젝트 맥락과 출처

2026-10-27에 현재 checkout과 기존 프로젝트 세션을 대조한 요약이다. 기능 구현 완료 기록이 아니다.
팀 결정은 최신 Confluence/Jira와 대조하며 이 파일에 원문 전체나 개인 대화·비밀값을 복제하지 않는다.

## 현재 코드 경계

- `services/roport-pinky`: Ubuntu 24.04 / ROS 2 Jazzy. 팀 패키지 `src/roport_pinky`, 원본 `src/pinky_pro`. 토픽·QoS·namespace·TF·timestamp는 실제 기체별 그래프 확인 후 확정한다.
- `services/roport-omx`: Python 코어 `src/roport_omx`, vendored LeRobot `lerobot`. 코어 환경과 학습/장비 환경을 분리하고 `UPSTREAM.md`의 고정 버전 API를 확인한다.
- `services/roport-control-server`: Python 3.12 / FastAPI, `src/roport_control_server/app.py`. 현장 작업·자원 배정·명령/상태와 출발 판단의 구현 영역이다.
- `services/roport-ai-server`: Python 3.12 / FastAPI, `src/app.py`. 입력·출력 schema와 모델 버전·전처리·유효 시간을 확인한다. AI 결과는 action 후보이며 직접 모터 구동 권한이 없다.
- `services/roport-service-server`: Java 21 / Spring Boot / Maven. 주문·예약·고객 검증·실제 수령 기록의 영역이며 `pom.xml`을 기준으로 한다.
- `services/roport-web`: Node.js 24 / React / TypeScript / Vite, npm workspaces `apps/service`, `apps/admin`. 고객/직원 업무와 관제 권한·상태 표시를 구분한다.

초기 entrypoint·health·CI와 원본 소스가 존재한다. WSS·MQTT·AI 전송·업무 DB·인증·양팔 공동 정책은 명세와 현재 코드의 구현 여부를 각각 확인해야 한다. 제안된 스택을 manifest에 이미 설치된 의존성처럼 취급하지 않는다.

## 설계 결정: 최신 명세 확인 후 사용

2026-10-27 live 조회 시 아래 Tech Spec 3건은 모두 v6였다.

- [서비스↔관제 · FFT1-55](https://fp-team1.atlassian.net/wiki/spaces/MFS/pages/10125388): 현장 관제가 원격 서비스에 WSS 연결을 시작한다. 서비스 업무 DB와 관제 운영 DB는 소유권을 분리한다. 요청 ID·outbox/inbox·application ack·replay/snapshot 계약을 구현 시 함께 검증한다.
- [MQTT·AI 통신 · FFT1-56](https://fp-team1.atlassian.net/wiki/spaces/MFS/pages/10125435): P0 로봇↔관제는 현장 Mosquitto MQTT, AI 입력·결과·오류는 UDP. P1에서 AI까지 EMQX Cloud MQTT로 통합하며 별도 부하·TLS·WAN 장애 검증 후 전환한다. P1 미완료는 P0 완료를 막지 않는다. ROS 2·장비 드라이버는 로봇 내부에 유지한다.
- [OMX1·2 반출 · FFT1-54](https://fp-team1.atlassian.net/wiki/spaces/MFS/pages/10027126): 같은 물품을 두 팔이 공동 반출한다. 관제는 작업·출발 허가, OMX Host는 양팔 구동·현장 정지를 소유한다. 학습 정책 밖의 실행 검사가 execution ID·관측 seq·deadline·관절/물품 상태를 확인한다.

MQTT QoS1/PUBACK·WSS 전송·추론 성공은 업무 접수나 장비 작업 완료가 아니다. 중복 command ID는 재구동을 일으키면 안 되며 retained cmd·만료·과거 세션 결과·순서 역전·재시작 후 결과 불명 상태를 검증한다.
안착·두 팔 안전 복귀·Pinky 준비를 확인한 뒤 출발하고, 운송 도착과 실제 고객 수령은 별도 상태다. 도킹 오차·제어 주기·관절 제한·추론 deadline은 실측/합의 전 임의로 확정하지 않는다.

명세와 구형 아키텍처의 DDS 화살표가 충돌하면 결정 시점과 적용 단계를 확인한다. 과거 Mosquitto 실험 수치를 EMQX Cloud 성능이나 로봇 안전성 근거로 확대하지 않는다.
요구사항·상위 구조·시나리오의 원문 링크는 [RO:PORT 문서 안내](https://github.com/kernel-robot-8th/kernel-robot-repo-1/blob/main/docs/README.md)를 사용한다.

## 이전 세션에서 이어받은 사항

- 「ROS 관제 기술 스택 조사」: 2026-10-26 P0/P1 결정과 Tech Spec·UML 갱신. 위 live v6 명세와 대조했다.
- 「main 최신화와 Graphify 검토」: 이후 사용자 결정은 `develop` 생략, `main`과 `task/**` 보호, 병합 후 source branch 자동 삭제였다. 과거 Git-flow 초안의 develop 경로를 자동 적용하지 않는다. 이 작업에서 원격 ruleset을 재검증하거나 변경하지 않았다.
- 「노션 테크스펙 템플릿 찾기」: SD-01/SD-03 시나리오, 상차·안전 복귀·출발과 수령 완료의 경계. 상세 판단은 최신 Tech Spec과 시나리오를 다시 읽는다.
- Pinky 내부 차선 인식·주행 알고리즘·Nav2는 별도 플러그인 `pinky-harness`(`pinky-harness:pinky-robotics`)가 맡는다. 설치 여부는 세션의 스킬 목록으로 확인한다.

Graphify 그래프가 있으면 관련 경로 탐색에 활용하되 갱신 시점과 실제 소스를 대조한다. 그래프가 없으면 필요한 팀 코드부터 읽고, 대규모 원본·모델 데이터 전체를 자동 추출하지 않는다.
