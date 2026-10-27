#!/usr/bin/env bash
# 하네스 정합성 검사: frontmatter, 오케스트레이터의 에이전트·참조 경로, v1 잔재
cd "$(dirname "$0")/.." || exit 1
fail=0
for f in agents/*.md skills/*/SKILL.md; do
  grep -q '^name:' "$f" && grep -q '^description:' "$f" || { echo "BAD frontmatter $f"; fail=1; }
done
for f in agents/*.md; do
  grep -q '^model:' "$f" || { echo "missing model $f"; fail=1; }
done
orch=skills/roport-orchestrator/SKILL.md
for a in $(grep -o 'roport-harness:[a-z-]*' "$orch" | sort -u); do
  [ -f "agents/${a#roport-harness:}.md" ] || { echo "unknown agent $a"; fail=1; }
done
for f in agents/*.md; do
  grep -q "roport-harness:$(basename "$f" .md)\`" "$orch" || { echo "agent not in orchestrator $f"; fail=1; }
done
for r in $(grep -rho 'references/[a-z-]*\.md' agents skills | sort -u); do
  [ -f "skills/roport-orchestrator/$r" ] || { echo "missing $r"; fail=1; }
done
! grep -rqE 'TeamCreate|TeamDelete|team_name|EXPERIMENTAL_AGENT_TEAMS' agents skills || { echo "v1 leftovers"; fail=1; }
[ ! -d commands ] && [ ! -d .claude/commands ] || { echo "commands dir not allowed"; fail=1; }
python3 -c 'import json,sys; [json.load(open(p)) for p in sys.argv[1:]]' .claude-plugin/*.json || fail=1
[ $fail = 0 ] && echo "check OK"
exit $fail
