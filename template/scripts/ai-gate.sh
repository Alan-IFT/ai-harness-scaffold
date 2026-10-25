#!/usr/bin/env bash
# ==============================================================================
# ai-gate.sh — 阶段门机械校验与推进（G1~G7）
# 原则：门禁不信任"AI 说完成了"，只认磁盘上的产物。
#
# 用法：
#   bash scripts/ai-gate.sh                                # 全局状态（含红线基线检查）
#   bash scripts/ai-gate.sh status [<feat>]                # 某个 / 全部 spec 的门禁状态
#   bash scripts/ai-gate.sh check <feat> <gate>            # 只校验，不推进
#   bash scripts/ai-gate.sh pass  <feat> <gate> [--force]  # 校验通过后记录（--force 越过前置门会记审计）
#   bash scripts/ai-gate.sh baseline                       # 人类确认红线后记录基线
#   bash scripts/ai-gate.sh reset <feat> <gate> [--reason "why"]  # 回退：使该门及之后的门失效
#
# 约定：
#   - <gate> 取 g1~g7；G6 的客观核验由 Agent 执行，②③另需人的明确决定及来源。
#   - 门禁状态写在 <spec>/.gates，由本脚本维护；手改它不会让 check 通过。
#   - 校验只是"最低机械门槛"，不能替代人工判断。
# ==============================================================================
set -u

SPEC_ROOT="process/specs"
REDLINES="harness/redlines.conf"
BASELINE="harness/.redlines.baseline"
FEAT=""
DIR=""

# 阈值只从当前项目配置读取；缺失或无效时明确拒绝。
. "$(dirname "${BASH_SOURCE[0]}")/ai-config.sh" || exit 1
ai_config_load "$REDLINES" CR_MAX_ROUNDS || exit 1

say() { printf '%s\n' "$*"; }
die() { printf '❌ %s\n' "$*" >&2; exit 1; }
ok()  { printf '✅ %s\n' "$*"; }

audit_ev() {   # $1=事件类型 $2=说明；写入 <spec>/.violations（随 spec 入库的审计流水）
  [ -n "${DIR:-}" ] && [ -d "$DIR" ] || return 0
  printf '%s\t%s\t%s\t%s\n' "$1" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${FEAT:-?}" "${2:-}" >>"$DIR/.violations"
}

gate_name() {
  case "$1" in
    g1) printf '需求澄清' ;; g2) printf '验收标准' ;; g3) printf '方案设计' ;;
    g4) printf '实现完成' ;; g5) printf '独立CR'   ;; g6) printf '交付核验' ;;
    g7) printf '归档'     ;; *)  printf '%s' "$1" ;;
  esac
}

quadrant() { # 当前 Spec 的需求象限；只读取字段行，避免把说明文字当作决定
  local line
  line=$(grep -E '^[[:space:]]*-[[:space:]]*需求分级（象限）' "$DIR/requirements.md" 2>/dev/null | head -n 1)
  # 多字节字符不能放进 []：字节 locale 下会被拆成单个字节，象限识别失败并跳过②③检查。
  printf '%s' "$line" | grep -oE '①|②|③|④' | head -n 1
}

feat_dir() {          # active 优先，其次 archive/YYYY-MM/<feat>
  local f="$1" d
  case "$f" in ''|.|..|*[!A-Za-z0-9._-]*) return 1 ;; esac
  [ -d "$SPEC_ROOT/active/$f" ] && { printf '%s' "$SPEC_ROOT/active/$f"; return 0; }
  d=$(find "$SPEC_ROOT/archive" -mindepth 2 -maxdepth 2 -type d -name "$f" 2>/dev/null | head -n 1)
  [ -n "$d" ] && { printf '%s' "$d"; return 0; }
  return 1
}

sha() {
  [ -f "$1" ] || return 1
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}'
  else cksum "$1" | awk '{print $1"-"$2}'; fi
}

# --- 文本抽取：二级标题下、到下一个二级标题为止 ---
# 全角空格归一分两层，不能只留一层（字节 locale 下全角空格不属于 [[:space:]]）：
#   1. section_body：覆盖按章节抽取的文本（需求四项、AC 表、设计各节、items）。
#   2. field_ok / field_value：还会直接收整份文件或单行原文（ck_g1 的原始问题、象限行、分级依据），
#      这些不经 section_body，必须自己归一。
#   直接读文件、不走上面两层且要判空的入口各自归一：需求覆盖矩阵（ck_trace_g3）、G5 / G6 的 nv。
#   其余直接读文件的入口只抽取固定符号或编号、不做空白判断，无需归一：quadrant（①~④）、
#   trace_requirement_ids 与 G6 的 ac_ids（REQ / ERR / AC 编号）。新增判空入口时须归一。
#   自检「LC_ALL=C：原始问题只有全角空格被拒」守住第 2 层。
section_body() {
  [ -f "$1" ] || return 0
  awk -v p="$2" '
    substr($0,1,3)=="## " {
      if (index(substr($0,4), p)==1) { inb=1; next }
      else if (inb) { exit }
    }
    inb { gsub("　", " "); print }
  ' "$1"
}

# stdin：筛出有实质内容的列表项 / 编号项（剔除模板占位符）
items() {
  grep -vE '^[[:space:]]*$' \
    | grep -E '^[[:space:]]*([-*]|[0-9]+[.)])[[:space:]]+' \
    | grep -vE '(path/to/|\{\{|<[^>]*>|（待填）|TODO)' || true
}

field_ok() {         # $1=section 正文 $2=标签：冒号后必须有实质内容且非占位符
  # 先把全角冒号归一化为半角：全角字符放进 [] 会被按字节拆开，导致空值被误判为已填。
  # 全角空格在字节 locale 下不属于 [[:space:]]，同样先归一，否则「冒号后只有全角空格」会被当成已填。
  # 调用方可能传整份文件原文（不经 section_body），所以这里的归一不能删，见 section_body 上方说明。
  local line val nv
  nv=$(printf '%s\n' "$1" | sed 's/：/:/g; s/　/ /g')
  line=$(printf '%s\n' "$nv" | grep -E "^[[:space:]]*[-*][[:space:]]*$2[[:space:]]*:" | head -n 1)
  [ -n "$line" ] || return 1
  val=$(printf '%s' "$line" | sed -E 's/^[^:]*:[[:space:]]*//; s/[[:space:]]+$//')
  [ -n "$val" ] || return 1
  case "$val" in '<'*|'{{'*|'['*|'__'*) return 1 ;; esac
  return 0
}
field_value() {
  printf '%s\n' "$1" | sed 's/：/:/g; s/　/ /g' \
    | sed -nE "s/^[[:space:]]*[-*][[:space:]]*$2[[:space:]]*:[[:space:]]*(.*)$/\1/p" \
    | head -n 1 | sed -E 's/[[:space:]]+$//'
}
need_items() {       # $1=文件 $2=section 前缀 $3=最少项数 $4=说明
  local body n
  body=$(section_body "$1" "$2")
  [ -n "$body" ] || { say "缺少「## $2」章节（$4）"; return 1; }
  n=$(printf '%s\n' "$body" | items | wc -l | tr -d ' ')
  [ "$n" -ge "$3" ] || { say "「$4」内容不足：$n 项 / 至少 $3 项"; return 1; }
  return 0
}

# ---------------------------------------------------------------- G1~G7 校验 --
ck_g1() {
  local f="$DIR/requirements.md" body missing=""
  [ -f "$f" ] || { say "缺少 $f"; return 1; }
  body=$(section_body "$f" "0.")
  [ -n "$body" ] || { say "requirements.md 缺少「## 0. 必须明确（四项）」"; return 1; }
  for label in 做什么 为谁做 关键业务规则 验收标准; do
    field_ok "$body" "$label" || missing="$missing $label"
  done
  [ -z "$missing" ] || { say "四项必答未填:$missing"; return 1; }
  field_ok "$(cat "$f")" '原始问题 / 原话' || { say "原始问题 / 原话未填：保留提出者的表达或链接需求入口"; return 1; }
  if section_body "$f" "4." | grep -qE '^[[:space:]]*[-*][[:space:]]*\[ \]'; then
    say "待确认问题未清零（「## 4.」仍有未勾选项）"; return 1
  fi
  # 需求分级（象限）与分级依据：决定谁做 G6 判断
  local q
  q=$(grep -E '需求分级' "$f" | head -n 1)
  [ -n "$q" ] || { say "requirements.md 缺少「需求分级（象限）」行（①~④ 之一 + 一句理由）"; return 1; }
  field_ok "$q" "需求分级（象限）" || { say "需求分级未填（①直接做 / ②人机协同·风险侧 / ③人机协同·复杂度侧 / ④暂不支持）"; return 1; }
  printf '%s' "$q" | grep -qE '①|②|③|④' || { say "需求分级未选象限（①/②/③/④）"; return 1; }
  case "$q" in *④*)
    printf '%s' "$q" | grep -qE '人工接管|转人工|不进入' || { say "象限④（暂不支持）必须写明「人工接管 / 转人工 / 不进入 AI 流水线」"; return 1; } ;;
  esac
  field_ok "$(cat "$f")" "分级依据" || { say "分级依据未填：风险来自哪里、复杂度来自哪里"; return 1; }
  return 0
}

ck_g2() {
  local f="$DIR/requirements.md" body bad
  [ -f "$f" ] || { say "缺少 $f"; return 1; }
  body=$(section_body "$f" "3.")
  [ -n "$body" ] || { say "缺少「## 3. 验收标准」"; return 1; }
  printf '%s\n' "$body" | grep -qE 'AC-[0-9]{2}' || { say "AC 表里没有 AC-xx 条目"; return 1; }
  printf '%s\n' "$body" | grep -q '不通过' || { say "AC 表缺少「不通过条件」"; return 1; }
  bad=$(printf '%s\n' "$body" | awk '/AC-[0-9][0-9]/ { n=split($0,a,"|"); for(i=2;i<n;i++) if (a[i] ~ /^[[:space:]]*$/) { print $0; break } }')
  [ -z "$bad" ] || { say "AC 表有空单元格（通过 / 不通过 / 量化证据必须填写）："; say "  $bad"; return 1; }
  return 0
}

trace_enabled() {
  grep -Eq '追溯版本(：|:)[[:space:]]*1' "$DIR/design.md" 2>/dev/null
}

trace_requirement_ids() {
  local req="$DIR/requirements.md"
  { grep -E '^[[:space:]]*[-*][[:space:]]*(\*\*)?(REQ|ERR)-[0-9]+' "$req" | grep -oE '(REQ|ERR)-[0-9]+'; awk -F'|' '{ id=$2; gsub(/^[[:space:]]+|[[:space:]]+$/, "", id); if (id ~ /^AC-[0-9]+$/) print id }' "$req"; } | sort -u
}

ck_trace_g3() {
  local matrix ids id rows
  matrix=$(awk '/^### 1[.]1 /{inside=1;next} /^## /{inside=0} inside' "$DIR/design.md" | sed 's/　/ /g')
  [ -n "$matrix" ] || { say "新 Spec 缺少 design.md §1.1 需求覆盖矩阵"; return 1; }
  ids=$(trace_requirement_ids)
  [ -n "$ids" ] || { say "新 Spec 缺少可追溯的 REQ/ERR/AC 编号"; return 1; }
  rows=$(printf '%s\n' "$matrix" | awk -F'|' '
    { id=$2; gsub(/^[[:space:]]+|[[:space:]]+$/, "", id);
      if (id ~ /^(REQ|ERR|AC)-[0-9]+$/) {
        for(i=3;i<=5;i++) {
          cell=$i; gsub(/^[[:space:]]+|[[:space:]]+$/, "", cell)
          if (cell=="" || cell ~ /原文关键短句|接口或|待填|TODO|<[^>]+>/) bad=1
        }
        print id
      }
    }
    END { if (bad) exit 2 }
  ') || { say "需求覆盖矩阵有空单元格或模板占位"; return 1; }
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    printf '%s\n' "$rows" | grep -qxF "$id" || { say "需求覆盖矩阵遗漏 $id"; return 1; }
  done <<<"$ids"
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    printf '%s\n' "$ids" | grep -qxF "$id" || { say "需求覆盖矩阵有无来源编号 $id"; return 1; }
  done <<<"$rows"
  return 0
}

ck_trace_g4() {
  local ids sections
  [ -f "$DIR/tasks.md" ] || return 1
  grep -Eq '追溯版本(：|:)[[:space:]]*1' "$DIR/tasks.md" || { say "新 Spec 的 tasks.md 缺少追溯版本标记"; return 1; }
  ids=$(trace_requirement_ids | tr '\n' ' ')
  sections=$(awk '/^#{2,6}[[:space:]]+[0-9]+([.][0-9]+)*[.]?([[:space:]]|$)/ { id=$2; sub(/[.]$/, "", id); print id }' "$DIR/design.md" | tr '\n' ' ')
  [ -n "$ids" ] && [ -n "$sections" ] || { say "任务追溯缺少需求编号或设计章节"; return 1; }
  awk -v ids="$ids" -v sections="$sections" '
    BEGIN {
      n=split(ids,a," "); for(i=1;i<=n;i++) if(a[i]!="") required[a[i]]=1
      n=split(sections,a," "); for(i=1;i<=n;i++) if(a[i]!="") section[a[i]]=1
    }
    function check_task(    s,id,ref,count) {
      if (!seen) return
      if (req=="" || design=="") { bad=1; return }
      s=req; count=0
      while (match(s,/(REQ|ERR|AC)-[0-9]+/)) {
        id=substr(s,RSTART,RLENGTH); count++
        if (!(id in required)) { print "任务引用不存在的需求编号 " id >"/dev/stderr"; bad=1 }
        covered[id]=1; s=substr(s,RSTART+RLENGTH)
      }
      if (!count) bad=1
      s=design; count=0
      while (match(s,/§[0-9]+([.][0-9]+)*/)) {
        ref=substr(s,RSTART,RLENGTH); sub(/^§/, "", ref); count++
        if (!(ref in section)) { print "任务引用不存在的设计章节 §" ref >"/dev/stderr"; bad=1 }
        s=substr(s,RSTART+RLENGTH)
      }
      if (!count) bad=1
    }
    /^[[:space:]]*-[[:space:]]*\[[xX]\].*Task/ {
      check_task(); seen=1; design=""; req=""; next
    }
    seen && /对应设计/ { design=$0 }
    seen && /对应需求[[:space:]]*\/[[:space:]]*验收/ { req=$0 }
    END {
      check_task()
      if (!seen) bad=1
      for (id in required) if (!(id in covered)) {
        print "需求编号未被任务承接 " id >"/dev/stderr"; bad=1
      }
      exit bad
    }
  ' "$DIR/tasks.md" || { say "新 Spec 的任务与需求编号或设计章节不一致"; return 1; }
}

ck_g3() {
  local f="$DIR/design.md" q steps
  [ -f "$f" ] || { say "缺少 $f"; return 1; }
  if { grep -q '^### 2[.]3 语义敏感原文锚点' "$DIR/requirements.md" || grep -Eq '追溯版本(：|:)[[:space:]]*1' "$DIR/tasks.md"; } && ! trace_enabled; then
    say "新 Spec 缺少 design.md 的追溯版本标记"; return 1
  fi
  grep -q 'path/to/' "$f" && { say "design.md 仍是模板占位路径（path/to/...），先替换成真实文件"; return 1; }
  q=$(quadrant)
  case "$q" in ①|②|③|④) ;; *) say "需求象限无效（须为 ①/②/③/④）"; return 1 ;; esac
  steps=2; [ "$q" = '①' ] && steps=1
  need_items "$f" "2." "$steps" "实现顺序（①可单步，其余至少 2 步）" || return 1
  need_items "$f" "4." 2 "影响面与文件清单" || return 1
  need_items "$f" "5." 1 "对抗自审" || return 1
  [ "$q" = '①' ] || section_body "$f" "2." | grep -q '检查点' || { say "「实现顺序」里没写检查点（每 2~3 步一个）"; return 1; }
  local scope decision
  scope=$(section_body "$f" "4.")
  field_ok "$scope" '间接消费者 / 副作用' || { say "影响面缺少间接消费者 / 副作用（无也需写依据）"; return 1; }
  field_ok "$scope" '检索依据' || { say "影响面缺少检索依据（搜索路径、符号或调用方）"; return 1; }
  if [ "$q" = '②' ] || [ "$q" = '③' ]; then
    decision=$(section_body "$f" "0.")
    field_ok "$decision" '人工前置决策' || { say "象限$q 缺少人工前置决策"; return 1; }
    printf '%s' "$decision" | grep -E '^[[:space:]]*-[[:space:]]*人工前置决策' | grep -qE '决策人.+结论' \
      || { say "象限$q 前置决策须写决策人、取舍与结论"; return 1; }
    printf '%s' "$decision" | grep -E '^[[:space:]]*-[[:space:]]*人工前置决策' | grep -qE '待确认|待定|待决|<[^>]+>|不适用' \
      && { say "象限$q 前置决策仍是占位或未完成"; return 1; }
    local boundary
    boundary=$(field_value "$(section_body "$f" "2.")" '边界样本')
    field_ok "$(section_body "$f" "2.")" '边界样本' \
      || { say "象限$q 设计须在 G3 列出边界样本，先检查非默认配置、极值与失败路径"; return 1; }
    case "$boundary" in 无|不适用|待*|TODO*|没有|无边界*)
      say "象限$q 的边界样本仍是占位词，须列具体输入或失败路径"; return 1 ;;
    esac
  fi
  # 模块关联：引用的模块活文档必须存在且已在 00-INDEX 登记（选错模块 = 架构漂移）
  local mods m n=0
  mods=$(section_body "$f" "0." | grep -oE '@?docs/architecture/modules/[A-Za-z0-9._-]+\.md' | sort -u)
  [ -n "$mods" ] || { say "design.md 缺少「## 0. 模块关联」或未填模块活文档（docs/architecture/modules/<module>.md）"; return 1; }
  for m in $mods; do
    m=${m#@}
    [ -f "$m" ] || { say "引用的模块活文档不存在：$m（先按 00-INDEX 选对或新建模块）"; return 1; }
    grep -qF "$m" docs/architecture/00-INDEX.md 2>/dev/null || { say "模块活文档未在 docs/architecture/00-INDEX.md 登记：$m"; return 1; }
    n=$((n+1))
  done
  section_body "$f" "0." | grep -q '契约入口' || { say "「## 0. 模块关联」缺少「契约入口」行"; return 1; }
  if section_body "$f" "0." | grep -E '契约入口' | grep -qE 'path/to/|<module>'; then
    say "契约入口仍是模板占位（path/to/ 或 <module>）"; return 1
  fi
  if [ "$q" != '①' ] && trace_enabled; then ck_trace_g3 || return 1; fi
  return 0
}

ck_g4() {
  local f="$DIR/tasks.md" open done summary result chk target spec saved_state current_state
  [ -f "$f" ] || { say "缺少 $f"; return 1; }
  if grep -Eq '追溯版本(：|:)[[:space:]]*1' "$f" && ! trace_enabled; then
    say "tasks.md 已启用追溯，但 design.md 缺少追溯版本标记"; return 1
  fi
  grep -q 'path/to/' "$f" && { say "tasks.md 仍含模板占位路径（path/to/...）"; return 1; }
  open=$(grep -cE '^[[:space:]]*[-*][[:space:]]*\[ \]' "$f" || true)
  done=$(grep -cE '^[[:space:]]*[-*][[:space:]]*\[[xX]\]' "$f" || true)
  open=$(printf '%s' "$open" | tr -d ' '); done=$(printf '%s' "$done" | tr -d ' ')
  [ "$open" -eq 0 ] || { say "还有 $open 个任务未完成"; return 1; }
  [ "$done" -ge 1 ] || { say "没有任何已完成任务"; return 1; }
  if [ "$(quadrant)" != '①' ] && trace_enabled; then ck_trace_g4 || return 1; fi
  summary="$DIR/verification.md"
  [ -f "$summary" ] || { say "没有可交接验证摘要：先跑 bash scripts/ai-verify.sh --spec $FEAT <file>"; return 1; }
  spec=$(sed -n 's/^- spec: //p' "$summary" | head -n 1)
  target=$(sed -n 's/^- target: //p' "$summary" | head -n 1)
  result=$(sed -n 's/^- result: //p' "$summary" | head -n 1)
  chk=$(sed -n 's/^- checks: //p' "$summary" | head -n 1)
  saved_state=$(sed -n 's/^- state: //p' "$summary" | head -n 1)
  [ "$spec" = "$FEAT" ] || { say "验证摘要的 Spec 不匹配：$spec"; return 1; }
  [ "$result" = PASS ] || { say "最近一次验证未通过：$summary"; return 1; }
  case "$chk" in ''|*[!0-9]*) say "验证摘要的 checks 无效"; return 1 ;; esac
  [ "$chk" -ge 1 ] || { say "验证摘要声称 0 项检查（未验证 ≠ 通过）"; return 1; }
  [ -n "$target" ] && [ -f "$target" ] || { say "验证摘要缺少有效目标文件：$target"; return 1; }
  [ -n "$saved_state" ] || { say "验证摘要缺少代码状态指纹"; return 1; }
  current_state=$(bash scripts/ai-state-id.sh --spec "$FEAT" "$target") || return 1
  [ "$saved_state" = "$current_state" ] || { say "验证摘要已过期：代码或 Git 暂存内容在验证后变化，请重新运行 ai-verify.sh"; return 1; }
  return 0
}

ck_g5() {
  local f="$DIR/review.md" nv rounds reviewed_state verified_state g3_format
  [ -f "$f" ] || { say "缺少 review.md：用独立上下文执行 .agents/skills/code-review.md 产出"; return 1; }
  nv=$(sed 's/：/:/g; s/　/ /g' <"$f")
  printf '%s\n' "$nv" | grep -q '^## 结论' || { say "review.md 缺少「## 结论」"; return 1; }
  printf '%s' "$nv" | grep -qE '关键问题.*:[[:space:]]*(0|无)' || { say "关键问题未清零（结论写「关键问题（必须修）：0」）"; return 1; }
  grep -q '审查者' "$f" || { say "review.md 缺少「审查者」署名（独立上下文标识）"; return 1; }
  grep -q '审查者.*<独立上下文标识' "$f" && { say "review.md 的「审查者」仍是模板占位（去掉 <...> 填真实上下文标识）"; return 1; }
  printf '%s' "$nv" | grep -qE '未参与实现.*:[[:space:]]*(是|yes)' || { say "review.md 未声明「未参与实现：是」（自己审自己不留痕 = 未审查）"; return 1; }
  { grep -q '判定' "$f" && grep -q '通过' "$f"; } || { say "review.md 判定未写「通过」"; return 1; }
  grep -qE '^[[:space:]]*[-*][[:space:]]*\[ \]' "$f" && { say "review.md 仍有未勾选项"; return 1; }
  # CR 修复包络：轮次必须记录且不超过 CR_MAX_ROUNDS（触顶转人工）
  rounds=$(printf '%s' "$nv" | grep -E 'CR 轮次' | head -n 1 | grep -oE '[0-9]+' | head -n 1)
  [ -n "$rounds" ] || { say "review.md 缺少「CR 轮次」（格式：- **CR 轮次**：N / $CR_MAX_ROUNDS）"; return 1; }
  [ "$rounds" -ge 1 ] || { say "CR 轮次至少为 1"; return 1; }
  [ "$rounds" -le "$CR_MAX_ROUNDS" ] || { say "CR 修复已达 $rounds 轮 > 上限 $CR_MAX_ROUNDS：停下转人工，禁止继续自我修复"; return 1; }
  # 新格式 G3 记录五列；旧 Spec 保持兼容，新审查须绑定被审代码状态。
  g3_format=$(awk -F'\t' '$1=="g3" { n=NF } END { print n }' "$DIR/.gates" 2>/dev/null)
  if [ "${g3_format:-0}" -ge 5 ]; then
    reviewed_state=$(printf '%s\n' "$nv" | sed -nE 's/^[[:space:]]*[-*][[:space:]]*审查状态:[[:space:]]*([A-Za-z0-9-]+).*$/\1/p' | head -n 1)
    verified_state=$(sed -n 's/^- state: //p' "$DIR/verification.md" | head -n 1)
    [ -n "$verified_state" ] && [ "$reviewed_state" = "$verified_state" ] \
      || { say "review.md 审查状态与当前 verification.md 不符，须重做独立审查"; return 1; }
  fi
  if trace_enabled; then
    for label in 需求追溯核对 'AI 协作文件审查' 审查范围限制; do
      field_ok "$nv" "$label" || { say "新 Spec 的 review.md 缺少「$label」结论与证据"; return 1; }
    done
  fi
  return 0
}

verdict_ok() { # $1=字段值：以「通过」开头，其后只能是行尾、空白或标点
  case "$1" in
    通过|'通过 '*|通过\;*|通过,*|通过.*|'通过('*|通过；*|通过，*|通过。*|通过、*|通过（*) return 0 ;;
  esac
  return 1
}

ck_g6() {
  local i g a="$DIR/acceptance.md" nv line val miss="" ac ac_ids
  for i in 1 2 3 4 5; do
    g="g$i"
    { [ -f "$DIR/.gates" ] && grep -qE "^$g[[:space:]]" "$DIR/.gates"; } || { say "前置门 $g 未通过"; return 1; }
  done
  [ -f "$DIR/verification.md" ] || { say "没有可交接验证摘要"; return 1; }
  ck_g4 || { say "G4 验证摘要已失效，先重新验证"; return 1; }
  [ -f "$DIR/review.md" ] || { say "没有 review.md"; return 1; }
  ck_g5 || { say "G5 审查结论已失效，先更新独立审查"; return 1; }
  # Agent 记录自己执行的客观核验；②③把人作出的决定与执行动作分开留痕。
  [ -f "$a" ] || { say "缺少 acceptance.md：G6 核验与决策必须留痕"; return 1; }
  nv=$(sed 's/：/:/g; s/　/ /g' <"$a")
  for label in 核验执行者 测试环境; do
    line=$(printf '%s\n' "$nv" | grep -E "^[[:space:]]*[-*][[:space:]]*$label[[:space:]]*:" | head -n 1)
    val=$(printf '%s' "$line" | sed -E 's/^[^:]*:[[:space:]]*//; s/[[:space:]]+$//')
    case "$val" in ''|'<'*|'__'*) miss="$miss $label" ;; esac
  done
  [ -z "$miss" ] || { say "acceptance.md 未填:$miss"; return 1; }
  # 三处只认行首结构化结论「通过」，后接证据文本不扫描；「通过率」「不通过」等不算。
  verdict_ok "$(field_value "$nv" '冒烟或 E2E 证据')" \
    || { say "acceptance.md「冒烟或 E2E 证据」须以「通过」开头，再写证据（旧格式请改写为「通过；<证据>」）"; return 1; }
  verdict_ok "$(field_value "$nv" '对照 AC 的检查结果')" \
    || { say "acceptance.md「对照 AC 的检查结果」须以「通过」开头，再写摘要"; return 1; }
  ac_ids=$(awk -F'|' '{ id=$2; gsub(/^[ \t]+|[ \t]+$/, "", id); if (id ~ /^AC-[A-Za-z0-9_-]+$/) print id }' "$DIR/requirements.md" | sort -u)
  [ -n "$ac_ids" ] || { say "requirements.md 缺少可逐项核验的 AC 编号"; return 1; }
  while IFS= read -r ac; do
    [ -n "$ac" ] || continue
    verdict_ok "$(field_value "$nv" "$ac")" || { say "acceptance.md 的 $ac 须以「通过」开头，再写证据"; return 1; }
  done <<<"$ac_ids"
  printf '%s' "$nv" | grep -qE '结论:[[:space:]]*通过' || { say "acceptance.md 判定未写「结论：通过」"; return 1; }
  case "$(quadrant)" in
    ②|③)
      for label in 人工决策人 决策来源; do
        line=$(printf '%s\n' "$nv" | grep -E "^[[:space:]]*[-*][[:space:]]*$label[[:space:]]*:" | head -n 1)
        val=$(printf '%s' "$line" | sed -E 's/^[^:]*:[[:space:]]*//; s/[[:space:]]+$//')
        case "$val" in ''|'<'*|'__'*) miss="$miss $label" ;; esac
      done
      [ -z "$miss" ] || { say "acceptance.md 未填:$miss"; return 1; }
      printf '%s' "$nv" | grep -qE '人工决定:[[:space:]]*通过' \
        || { say "象限②③需要人的明确通过决定，Agent 不能代作决定（旧格式请去掉委托字段，人工决定写「通过」）"; return 1; }
      ;;
    ①) ;;
    *) say "G6 缺少有效需求象限"; return 1 ;;
  esac
  return 0
}

ck_g7() {
  case "$DIR" in
    "$SPEC_ROOT"/active/*) say "spec 还在 active 目录，先按 archive-spec.md 归档"; return 1 ;;
  esac
  return 0
}

check_gate() {
  if [ "$1" != g1 ] && [ "$(quadrant)" = '④' ]; then
    say "象限④只做分析与人工移交，不进入 G2~G7 自动开发流程"; return 1
  fi
  case "$1" in
    g1) ck_g1 ;; g2) ck_g2 ;; g3) ck_g3 ;; g4) ck_g4 ;;
    g5) ck_g5 ;; g6) ck_g6 ;; g7) ck_g7 ;;
    *) say "未知门 $1（可选 g1~g7）"; return 1 ;;
  esac
}

# ---------------------------------------------------------------- 红线基线 --
redline_state() {     # ok | drift | unbaselined | missing
  [ -f "$REDLINES" ] || { printf 'missing'; return 0; }
  [ -f "$BASELINE" ] || { printf 'unbaselined'; return 0; }
  if [ "$(sha "$REDLINES")" = "$(cat "$BASELINE" 2>/dev/null)" ]; then printf 'ok'; else printf 'drift'; fi
}

ensure_baseline() {
  [ -f "$REDLINES" ] || return 0
  [ -f "$BASELINE" ] && return 0
  mkdir -p "$(dirname "$BASELINE")"
  sha "$REDLINES" > "$BASELINE"
  say "ℹ️  已记录红线初始基线。若你此前手工改过红线，请人工重跑：bash scripts/ai-gate.sh baseline"
}

guard_redlines() {
  case "$(redline_state)" in
    drift)
      say "🚫 红线配置已变更（漂移）（harness/redlines.conf 与基线不符）。"
      say "   若确属人类有意修改，请在交互终端执行：bash scripts/ai-gate.sh baseline"
      return 1 ;;
    unbaselined) ensure_baseline ;;
  esac
  return 0
}

# ---------------------------------------------------------------- 子命令 -----
cmd_check() {
  FEAT="${1:-}"; local gate="${2:-}"
  [ -n "$FEAT" ] && [ -n "$gate" ] || die "用法：ai-gate.sh check <feat> <gate>"
  gate=$(printf '%s' "$gate" | tr 'A-Z' 'a-z')
  DIR=$(feat_dir "$FEAT") || die "找不到 spec: $FEAT（先 bash scripts/ai-new-spec.sh $FEAT）"
  if check_gate "$gate"; then ok "$FEAT 门 $gate（$(gate_name "$gate")）校验通过"; else die "$FEAT 门 $gate 校验未通过"; fi
}

cmd_pass() {
  [ $# -ge 2 ] || die "用法：ai-gate.sh pass <feat> <gate> [--force]"
  FEAT="$1"; local gate; gate=$(printf '%s' "$2" | tr 'A-Z' 'a-z')
  shift 2
  local force=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --force) force=1; shift ;;
      *) die "未知参数 $1" ;;
    esac
  done
  case " g1 g2 g3 g4 g5 g6 g7 " in *" $gate "*) ;; *) die "未知门 $gate（可选 g1~g7）" ;; esac
  DIR=$(feat_dir "$FEAT") || die "找不到 spec: $FEAT（先 bash scripts/ai-new-spec.sh $FEAT）"
  guard_redlines || exit 1
  local n i
  n=${gate#g}; i=1
  while [ "$i" -lt "$n" ]; do
    if ! { [ -f "$DIR/.gates" ] && grep -qE "^g$i[[:space:]]" "$DIR/.gates"; }; then
      if [ "$force" -eq 1 ]; then
        say "⚠️  --force：跳过未通过的前置门 g$i（已记入 .violations 审计）"
        audit_ev "force-skip" "跳过未通过的前置门 g$i"
      else
        die "前置门 g$i 未通过（先 pass g$i）"
      fi
    fi
    i=$((i+1))
  done
  if ! check_gate "$gate" >/dev/null 2>&1; then check_gate "$gate"; die "门禁校验未通过，拒绝推进 $gate"; fi
  if [ "$gate" = g3 ]; then
    # G3 记录第 4 列为基准提交；第 5 列为保留列（恒为 none），G5 按 5 列格式绑定审查状态。
    local base="-"
    if git rev-parse --verify -q HEAD >/dev/null 2>&1; then base=$(git rev-parse HEAD); fi
    printf '%s\t%s\t%s\t%s\t%s\n' "$gate" agent "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$base" none >> "$DIR/.gates"
  else
    printf '%s\t%s\t%s\n' "$gate" agent "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$DIR/.gates"
  fi
  ok "$FEAT 已通过 $gate（$(gate_name "$gate")）"
  say "   下一步：bash scripts/ai-gate.sh status $FEAT"
}

cmd_reset() {   # 回退：使 <gate> 及之后的门失效（需求/设计变更、代码回滚后必须执行）
  [ $# -ge 2 ] || die "用法：ai-gate.sh reset <feat> <gate> [--reason \"why\"]"
  FEAT="$1"; local gate; gate=$(printf '%s' "$2" | tr 'A-Z' 'a-z'); shift 2
  local reason=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --reason) reason="${2:-}"; shift 2 ;;
      *) die "未知参数 $1" ;;
    esac
  done
  case " g1 g2 g3 g4 g5 g6 g7 " in *" $gate "*) ;; *) die "未知门 $gate（可选 g1~g7）" ;; esac
  DIR=$(feat_dir "$FEAT") || die "找不到 spec: $FEAT"
  [ -f "$DIR/.gates" ] || die "$FEAT 没有任何门记录，无需回退"
  local n removed
  n=${gate#g}
  removed=$(awk -F'\t' -v n="$n" '$1 ~ /^g[0-9]+$/ && substr($1,2)+0 >= n' "$DIR/.gates" | wc -l | tr -d ' ')
  [ "$removed" -gt 0 ] || die "$FEAT 的 $gate 及之后没有已通过的门记录（无需回退）"
  awk -F'\t' -v n="$n" '$1 !~ /^g[0-9]+$/ || substr($1,2)+0 < n' "$DIR/.gates" > "$DIR/.gates.tmp"
  mv "$DIR/.gates.tmp" "$DIR/.gates"
  audit_ev "reset" "回退 $gate 及之后（移除 $removed 条）：${reason:-未说明原因}"
  ok "$FEAT 已回退：$gate 及之后的 $removed 条门记录失效"
  say "   含义：需求 / 设计 / 代码已变更，必须重新逐门校验并 pass。"
  say "   下一步：bash scripts/ai-gate.sh status $FEAT"
}

render_spec() {
  local d="$1" f i g when next="" out
  f=$(basename "$d"); DIR="$d"; FEAT="$f"
  say ""
  say "📂 $f   ($d)"
  for i in 1 2 3 4 5 6 7; do
    g="g$i"
    if [ -f "$DIR/.gates" ] && grep -qE "^$g[[:space:]]" "$DIR/.gates"; then
      when=$(grep -E "^$g[[:space:]]" "$DIR/.gates" | tail -n 1 | awk '{print $3}')
      printf '   %s %-8s ✅ %s\n' "$g" "$(gate_name "$g")" "$when"
    else
      printf '   %s %-8s ⬜\n' "$g" "$(gate_name "$g")"
      [ -z "$next" ] && next="$g"
    fi
  done
  if [ -f "$DIR/.violations" ]; then
    say "   🧾 审计事件：$(wc -l <"$DIR/.violations" | tr -d ' ') 条（$DIR/.violations）"
  fi
  if [ "$(quadrant)" = '④' ] && [ -f "$DIR/.gates" ] && grep -qE '^g1[[:space:]]' "$DIR/.gates"; then
    say "   ↪ 已分类为④：记录人工移交，在 docs/INTAKE.md 留决定并将 Spec 移入 archive；不进入 G2~G7。"
    return 0
  fi
  [ -z "$next" ] && { say "   🎉 全部门已通过，可收尾归档。"; return 0; }
  if out=$(check_gate "$next" 2>&1); then
    say "   下一门：$next（$(gate_name "$next")）"
    say "   可推进：bash scripts/ai-gate.sh pass $f $next"
  else
    say "   下一门：$next（$(gate_name "$next")）"
    say "   阻断原因：$out"
  fi
}

cmd_status() {
  local feat="${1:-}" d any=0
  say "== 阶段门状态 (ai-gate.sh) =="
  case "$(redline_state)" in
    ok)          say "🔒 红线基线：一致（$(sha "$REDLINES" | cut -c1-12)…）" ;;
    drift)       say "🚫 红线基线：漂移！harness/redlines.conf 被改动过，所有 pass 都会被阻断。"
                 say "   若属人类有意修改，请在交互终端执行：bash scripts/ai-gate.sh baseline" ;;
    unbaselined) ensure_baseline ;;
    missing)     say "ℹ️  未找到 harness/redlines.conf（可从脚手架模板补回）。" ;;
  esac
  if [ -n "$feat" ]; then
    d=$(feat_dir "$feat") || die "找不到 spec: $feat"
    render_spec "$d"; return 0
  fi
  for d in "$SPEC_ROOT"/active/*/; do
    [ -d "$d" ] || continue
    render_spec "${d%/}"; any=1
  done
  [ "$any" -eq 1 ] || { say ""; say "  当前无活跃 Spec。新建：bash scripts/ai-new-spec.sh <feat-name>"; }
}

# 只从 .gates 计算有证据的门间耗时；不猜需求起点或人工等待。
gate_epoch() {
  local stamp="$1"
  date -u -d "$stamp" +%s 2>/dev/null \
    || date -j -u -f '%Y-%m-%dT%H:%M:%SZ' "$stamp" +%s 2>/dev/null
}
cmd_metrics() {
  local feat="${1:-}" d from to a b ea eb
  [ -n "$feat" ] || die "用法：ai-gate.sh metrics <feat>"
  d=$(feat_dir "$feat") || die "找不到 spec: $feat"
  say "== $feat 门间耗时（来源：$d/.gates）=="
  for pair in 'g3 g4' 'g4 g6' 'g5 g6'; do
    read -r from to <<<"$pair"
    a=$(awk -F'\t' -v g="$from" '$1==g { t=$3 } END { print t }' "$d/.gates" 2>/dev/null)
    b=$(awk -F'\t' -v g="$to" '$1==g { t=$3 } END { print t }' "$d/.gates" 2>/dev/null)
    ea=$(gate_epoch "$a"); eb=$(gate_epoch "$b")
    if [ -n "$ea" ] && [ -n "$eb" ] && [ "$eb" -ge "$ea" ]; then
      say "$from → $to: $((eb - ea)) 秒"
    else
      say "$from → $to: 未知"
    fi
  done
  say "人工 / 外部等待：未知（除非另有带时间戳的证据）"
}

cmd_baseline() {
  [ -f "$REDLINES" ] || die "找不到 $REDLINES"
  [ -t 0 ] || die "红线基线需要在交互终端（TTY）确认；此检查只防误操作，不提供身份认证"
  sha "$REDLINES" > "$BASELINE"
  ok "已记录红线基线：$(sha "$REDLINES" | cut -c1-12)…"
  say "   含义：确认「harness/redlines.conf 的本次变更是人类有意为之」。"
}

main() {
  local cmd="${1:-status}"
  [ $# -gt 0 ] && shift
  case "$cmd" in
    status)   cmd_status "${1:-}" ;;
    metrics)  cmd_metrics "${1:-}" ;;
    check)    cmd_check "$@" ;;
    pass)     cmd_pass "$@" ;;
    reset)    cmd_reset "$@" ;;
    baseline) cmd_baseline ;;
    -h|--help|help) sed -n '3,17p' "$0" | sed 's/^# \{0,1\}//' ;;
    *) die "未知命令 $cmd（可用：status / check / pass / reset / baseline）" ;;
  esac
}

main "$@"
