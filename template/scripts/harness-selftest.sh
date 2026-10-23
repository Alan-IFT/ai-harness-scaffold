#!/usr/bin/env bash
# ==============================================================================
# harness-selftest.sh — 门禁自检 / Dry Run（策略即代码）
#
# 为什么需要它：门禁本身也是代码。换模型、换工具、改脚本之后，如果没人验证过
# "该拦的还拦得住"，门禁随时会退化成摆设（比如报告只要存在就算通过）。
# 本脚本把脚手架复制到临时目录，用"应该被拒"的坏样例和"应该通过"的好样例，
# 逐条断言 ai-gate.sh / ai-verify.sh 的退出码与关键提示。
#
# 用法：bash scripts/harness-selftest.sh
# 退出码：0 = 全部通过；1 = 有断言失败（失败详情直接打印）
# 建议：接进 CI 的 harness job，改 scripts/ai-gate.sh 或 redlines 后必跑。
# ==============================================================================
set -u

ROOT=$(cd "$(dirname "$0")/.." && pwd) || exit 1
TMP=$(mktemp -d "${TMPDIR:-/tmp}/harness-selftest-XXXXXX") || exit 1
trap 'rm -rf "$TMP"' EXIT

SB="$TMP/scaffold"
mkdir -p "$SB/docs/specs" "$SB/harness"
cp -r "$ROOT/scripts" "$SB/scripts"
cp -r "$ROOT/docs/specs/_templates" "$SB/docs/specs/_templates"
cp "$ROOT/harness/redlines.conf" "$SB/harness/redlines.conf"
# 自检用固定夹具阈值；目标项目可以合法选择不同数值。
sed -i -e 's/^FEASIBILITY_MIN=.*/FEASIBILITY_MIN=60/' \
       -e 's/^CR_MAX_ROUNDS=.*/CR_MAX_ROUNDS=4/' \
       -e 's/^VERIFY_MAX_ATTEMPTS=.*/VERIFY_MAX_ATTEMPTS=3/' "$SB/harness/redlines.conf"
cp "$SB/harness/redlines.conf" "$TMP/redlines.fixture"
# 架构路由表与模块活文档（G3 模块关联校验需要）
mkdir -p "$SB/docs/architecture/modules"
cat >"$SB/docs/architecture/00-INDEX.md" <<'MD'
# 架构活文档路由表

| 模块 | 代码路径 | 契约入口 | 活文档 |
| :-- | :-- | :-- | :-- |
| 导出 | `src/export/` | `src/export/index.ts` | `docs/architecture/modules/example-export.md` |
MD
printf '# 模块：导出\n\n## 公共契约\n- `createExport(uid, filter): Promise<TaskId>`\n' >"$SB/docs/architecture/modules/example-export.md"
printf '# 模块：故意未登记（G3 负样例用）\n' >"$SB/docs/architecture/modules/unregistered-export.md"
# 不复制基线：让沙箱里的门禁自行记录初始基线（顺带验证 ensure_baseline 路径）
cd "$SB" || exit 1
mkdir -p src/export
printf 'export function createExport() { return true; }\n' >src/export/service.ts

TOTAL=0; FAILED=0
SECTION_NAME=""; SECTION_START=$SECONDS
section() {
  if [ -n "$SECTION_NAME" ]; then
    printf '== %s: %ss ==\n' "$SECTION_NAME" "$((SECONDS - SECTION_START))"
  fi
  SECTION_NAME="$1"; SECTION_START=$SECONDS
  printf '== %s ==\n' "$SECTION_NAME"
}
ok_msg() { TOTAL=$((TOTAL + 1)); printf '  ✅ %s\n' "$1"; }
ng_msg() {
  TOTAL=$((TOTAL + 1)); FAILED=$((FAILED + 1))
  printf '  ❌ %s\n' "$1"
  [ -n "${2:-}" ] && printf '%s\n' "$2" | head -n 5 | sed 's/^/     | /'
}

expect_ok() {   # $1=描述；其余=命令
  local desc="$1" out rc; shift
  out=$("$@" 2>&1); rc=$?
  if [ "$rc" -eq 0 ]; then ok_msg "$desc"; else ng_msg "$desc（期望 exit 0，实际 $rc）" "$out"; fi
}

expect_fail() { # $1=描述 $2=期望提示片段（可空）；其余=命令
  local desc="$1" want="$2" out rc; shift 2
  out=$("$@" 2>&1); rc=$?
  if [ "$rc" -eq 0 ]; then
    ng_msg "$desc（本应被拒，实际 exit 0）" "$out"
  elif [ -n "$want" ] && ! printf '%s' "$out" | grep -q -- "$want"; then
    ng_msg "$desc（被拒了，但原因不含「$want」）" "$out"
  else
    ok_msg "$desc"
  fi
}

expect_out() {  # $1=描述 $2=期望输出片段；其余=命令（要求命令成功且输出命中）
  local desc="$1" want="$2" out rc; shift 2
  out=$("$@" 2>&1); rc=$?
  if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q -- "$want"; then
    ok_msg "$desc"
  else
    ng_msg "$desc（有输出但没有「$want」）" "$out"
  fi
}

file_has() {    # $1=描述 $2=文件 $3=片段
  if grep -q -- "$3" "$2" 2>/dev/null; then ok_msg "$1"; else ng_msg "$1（$2 里没有「$3」）"; fi
}
file_lacks() {  # $1=描述 $2=文件 $3=片段
  if grep -q -- "$3" "$2" 2>/dev/null; then ng_msg "$1（$2 里仍有「$3」）"; else ok_msg "$1"; fi
}

# ---------------------------------------------------------------- 样例生成器 --
make_report() {   # $1=reports 目录：模拟 ai-verify.sh 真实产出
  local state spec
  mkdir -p "$1"
  cat >"$1/verify-20990101-000000.log" <<'MD'
# verify: ai-verify.sh
# target: src/export/service.ts
# result: PASS
# checks: 2  failed: 0  duration: 1s
### ESLint 单文件
### Vitest related
MD
  spec=$(basename "$(dirname "$1")")
  state=$(bash scripts/ai-state-id.sh --spec "$spec" src/export/service.ts)
  cat >"$(dirname "$1")/verification.md" <<MD
# 增量验证摘要

- spec: $spec
- target: src/export/service.ts
- result: PASS
- checks: 2
- state: $state
- command: bash scripts/ai-verify.sh --spec $spec src/export/service.ts
MD
}

good_spec() {     # $1=spec 目录：应能通过 G1~G5 的完整样例
  local d="$1"
  mkdir -p "$d/reports"
  cat >"$d/requirements.md" <<'MD'
# 需求与验收规范 (Requirements): selftest

- 原始问题 / 原话：运营同学说现在只能手工导出数据

## 0. 必须明确（四项）
- 需求分级（象限）：②人机协同·风险侧 —— 理由：只读导出，但涉及用户数据导出权限
- 分级依据：风险来自数据越权导出；复杂度低（单接口 + 异步任务）
- 做什么：导出用户可下载的 CSV
- 为谁做：运营同学
- 关键业务规则：单次最多 5 万行，超限拒绝并提示分批
- 验收标准：见第 3 节 AC 表

## 1. 背景与目标
导出能力缺失，运营只能手工导数据。

## 2. 结构化需求（EARS）
WHEN 用户点击导出，THE SYSTEM SHALL 生成 CSV 下载任务。

## 3. 验收标准
| 编号 | 验收点 | 通过条件 | 不通过条件 | 量化指标 / 证据 |
| :-- | :-- | :-- | :-- | :-- |
| AC-01 | 正常导出 | 返回任务 id 且可下载 | 报错或超时 | 建任务 < 2s |

## 4. 待确认问题
- 无

## 5. 非功能性约束
安全：仅本人可下载自己的导出文件。

## 6. 可行性自评（7 维加权）
| 维度 | 权重 | 分数(0~10) | 得分 |
| :-- | :-- | :-- | :-- |
| 需求清晰度 | 20 | 9 | 18 |
| 仓库·模块匹配度 | 20 | 8 | 16 |
| 改动范围可控度 | 15 | 8 | 12 |
| 技术复杂度 | 15 | 8 | 12 |
| 外部依赖就绪度 | 10 | 8 | 8 |
| 风险等级 | 10 | 6 | 6 |
| 交付形态清晰度 | 10 | 8 | 8 |
- 加权总分：80 / 100
MD
  cat >"$d/design.md" <<'MD'
# 技术架构与接口设计 (Design): selftest

## 0. 模块关联（先确认改哪个模块）
- 主模块：export → `docs/architecture/modules/example-export.md`
- 涉及模块：无
- 契约入口（只读）：`src/export/index.ts`
- 人工前置决策：决策人=运营负责人；风险取舍=限制每人导出；结论=同意测试环境验证

## 1. 架构与数据流
Controller → ExportService → 导出任务表。

## 2. 实现顺序（依赖图 + 垂直切片）
1. 存储层：导出任务表与索引
2. 协议层：任务创建接口
3. 逻辑层：CSV 生成与下载
检查点：完成第 1、2 步后各跑一次增量验证。
- 边界样本：并发超限、无权限、任务失败和空导出。

## 3. 契约与 Schema
新增表 export_task（id、uid、status、created_at）。

## 4. 影响面与文件清单
- src/export/service.ts：实现导出与上限校验
- src/export/controller.ts：暴露创建与下载接口
- 间接消费者 / 副作用：下载任务、权限与操作日志；没有跨仓库消费者，依据仓库搜索。
- 检索依据：已搜索 src/export、鉴权入口和任务调度引用。

## 5. 对抗自审
1. 假设作者过度自信：5 万行上限能否被并发绕过？
MD
  cat >"$d/tasks.md" <<'MD'
# 原子执行队列与跨工具接力棒 (Tasks): selftest

## 0. 阶段门
见 ai-gate.sh。

## 1. 上下文清单
- 必读：requirements.md、design.md、本文件
- 注入知识：无相关卡片
- 知识检索：模块 export；当前无候选，已核对模块活文档。

## 2. 原子任务序列
- [x] Task 1: 建导出任务表与索引
- [x] Task 2: 实现接口与上限校验
MD
  cat >"$d/review.md" <<'MD'
# 代码审查报告 (Code Review): selftest

- **审查者**：selftest-session-b
- **未参与实现**：是
- **审查时间**：2026-10-20
- **CR 轮次**：1 / 4

## 结论
- 关键问题（必须修）：0
- 改进建议（非阻塞）：1
- 判定：通过

## 关键问题（bug / 崩溃 / 安全 / 数据损坏 / 功能缺失 / 越权）
无

## 安全六项核对
| 项 | 结果 | 证据 |
| :-- | :-- | :-- |
| UID 取自登录态 | ✅ | src/export/controller.ts:12 |
MD
  make_report "$d/reports"
  printf '%s\n' "- 审查状态：$(sed -n 's/^- state: //p' "$d/verification.md" | head -n 1)" >>"$d/review.md"
  cat >"$d/acceptance.md" <<'MD'
# 交付核验报告 (Acceptance): selftest

- 核验执行者：selftest-agent
- 核验时间：2026-10-20
- 测试环境：测试环境 t-env（部署记录见 reports/）
- 冒烟或 E2E 证据：verification.md 的两项检查通过；本机日志见 reports/

## 1. 核验摘要
- 对照 AC 的检查结果：逐项通过，见 verification.md
- AC-01：通过，见 verification.md
- 需人判断的风险 / 遗留：导出权限由运营负责人决定

## 2. 决策与结论
- 人工决策人：运营负责人
- 人工决定：通过
- 决策来源：测试用例中的模拟对话决定
- 结论：通过
MD
}

mk_spec() {       # $1=feat：在沙箱里造一个好样例 spec
  mkdir -p "docs/specs/active/$1"
  good_spec "docs/specs/active/$1"
}

# ==============================================================================
section "1. 模板生成与参数校验"
expect_ok   "ai-new-spec 生成新 spec 文档" bash scripts/ai-new-spec.sh t-empty
expect_fail "ai-new-spec 拒绝无参" "请提供功能名称" bash scripts/ai-new-spec.sh
expect_fail "ai-new-spec 拒绝同名重复" "已存在" bash scripts/ai-new-spec.sh t-empty
mkdir -p docs/specs/archive/2026-10/t-archived-id
expect_fail "ai-new-spec 拒绝重用已归档 ID" "已归档，不能重用" bash scripts/ai-new-spec.sh t-archived-id
expect_fail "ai-new-spec 拒绝路径别名" "只允许" bash scripts/ai-new-spec.sh ..
file_has "新 spec 含 acceptance.md（G6 留痕）" docs/specs/active/t-empty/acceptance.md "核验执行者"
file_has "新 spec 含 verification.md（跨 IDE 接力）" docs/specs/active/t-empty/verification.md "UNVERIFIED"

section "2. 空模板必须被逐门拒绝（模板占位不能算完成）"
expect_fail "G1 拒绝未澄清的需求" "四项必答" bash scripts/ai-gate.sh check t-empty g1
expect_fail "G2 拒绝空 AC 表" "AC 表有空单元格" bash scripts/ai-gate.sh check t-empty g2
mk_spec t-vague
sed -i 's/^| AC-01 | .*/| AC-01 | 导出 | 尽量 2s 内返回 | 超时 | 计时 |/' docs/specs/active/t-vague/requirements.md
expect_fail "G2 拒绝 AC 含糊词并指出命中词" "含糊词：尽量" bash scripts/ai-gate.sh check t-vague g2
sed -i 's/^| AC-01 | .*/| AC-01 | 导出 | Etc. 格式都支持 | 报错 | 样例 |/' docs/specs/active/t-vague/requirements.md
expect_fail "G2 英文含糊词不分大小写" "含糊词：etc" bash scripts/ai-gate.sh check t-vague g2
sed -i 's/^| AC-01 | .*/| AC-01 | 文案 | 按钮显示「尽快处理。」与 `ASAP` | 文案不符 | 合理性校验返回 400 |/' docs/specs/active/t-vague/requirements.md
expect_ok "G2 放行引号内原文与复合词（字节 locale）" env LC_ALL=C bash scripts/ai-gate.sh check t-vague g2
expect_fail "G3 拒绝模板占位路径 path/to/" "path/to" bash scripts/ai-gate.sh check t-empty g3
expect_fail "G4 拒绝模板占位路径 path/to/" "path/to" bash scripts/ai-gate.sh check t-empty g4
expect_fail "G5 拒绝缺失的 review.md" "review.md" bash scripts/ai-gate.sh check t-empty g5

# 需求分级 / 可行性总分 / 待确认清零（需求侧质量前移）
mk_spec t-pending
sed -i 's/^- 无$/- 无\n- [ ] Q1：是否需要断点续传？/' docs/specs/active/t-pending/requirements.md
expect_fail "G1 拒绝待确认问题未清零" "待确认" bash scripts/ai-gate.sh check t-pending g1
mk_spec t-noorigin
sed -i '/^- 原始问题 \/ 原话：/d' docs/specs/active/t-noorigin/requirements.md
expect_fail "G1 拒绝丢失提出者原意" "原始问题" bash scripts/ai-gate.sh check t-noorigin g1
mk_spec t-lowfeas
sed -i 's/^- 加权总分：.*/- 加权总分：30 \/ 100/' docs/specs/active/t-lowfeas/requirements.md
sed -i '/^- 加权总分：/i\> 门禁说明中的加权总分：<60 或 >100 直接拒绝。' docs/specs/active/t-lowfeas/requirements.md
expect_fail "G1 拒绝可行性 <60" "60" bash scripts/ai-gate.sh check t-lowfeas g1
mk_spec t-score-mismatch
sed -i 's/^- 加权总分：.*/- 加权总分：90 \/ 100/' docs/specs/active/t-score-mismatch/requirements.md
expect_fail "G1 拒绝自报总分与表格不一致" "计算值" bash scripts/ai-gate.sh check t-score-mismatch g1
mk_spec t-quad4
sed -i 's/^- 需求分级（象限）：.*/- 需求分级（象限）：④暂不支持 —— 理由：跨仓库联动/' docs/specs/active/t-quad4/requirements.md
expect_fail "G1 象限④必须写明人工接管" "人工接管" bash scripts/ai-gate.sh check t-quad4 g1
sed -i 's/^- 需求分级（象限）：.*/- 需求分级（象限）：④暂不支持，人工接管跨仓库联动/' docs/specs/active/t-quad4/requirements.md
sed -i '/^- 加权总分：/d' docs/specs/active/t-quad4/requirements.md
expect_ok "G1 允许④完成分类移交，无需凑可行性评分" bash scripts/ai-gate.sh check t-quad4 g1
expect_fail "象限④不得进入 G2" "人工移交" bash scripts/ai-gate.sh check t-quad4 g2
expect_fail "象限④即使用 --force 也不能推进 G3" "人工移交" bash scripts/ai-gate.sh pass t-quad4 g3 --force
expect_ok "象限④可记录 G1 分类" bash scripts/ai-gate.sh pass t-quad4 g1
expect_out "象限④状态提示移出 active" "移入 archive" bash scripts/ai-gate.sh status t-quad4

mk_spec t-quad1
sed -i 's/^- 需求分级（象限）：.*/- 需求分级（象限）：①直接做，低风险单文件改动/' docs/specs/active/t-quad1/requirements.md
sed -i '/^2\. 协议层\|^3\. 逻辑层\|^检查点：/d' docs/specs/active/t-quad1/design.md
sed -i '/^- src\/export\/controller.ts：/d' docs/specs/active/t-quad1/design.md
sed -i '/^- 人工前置决策：/d' docs/specs/active/t-quad1/design.md
expect_ok "象限①允许单步精简设计" bash scripts/ai-gate.sh check t-quad1 g3

mk_spec t-quad3
sed -i 's/^- 需求分级（象限）：.*/- 需求分级（象限）：③人机协同·复杂度侧，需前置架构拆分/' docs/specs/active/t-quad3/requirements.md
expect_ok "象限③有前置决策可进入设计门" bash scripts/ai-gate.sh check t-quad3 g3

mk_spec t-nodecision
sed -i '/^- 人工前置决策：/d' docs/specs/active/t-nodecision/design.md
expect_fail "象限②缺前置决策被 G3 拒绝" "人工前置决策" bash scripts/ai-gate.sh check t-nodecision g3
mk_spec t-noimpact
sed -i '/^- 间接消费者 \/ 副作用：/d' docs/specs/active/t-noimpact/design.md
expect_fail "G3 拒绝漏查间接消费者" "间接消费者" bash scripts/ai-gate.sh check t-noimpact g3
mk_spec t-nosearch
sed -i '/^- 检索依据：/d' docs/specs/active/t-nosearch/design.md
expect_fail "G3 拒绝无检索依据" "检索依据" bash scripts/ai-gate.sh check t-nosearch g3

mk_spec t-open
printf '\n- [ ] Task 3: 补一个未完成任务\n' >>docs/specs/active/t-open/tasks.md
expect_fail "G4 拒绝未完成任务" "未完成" bash scripts/ai-gate.sh check t-open g4

# 模块关联（design.md §0 必须选对模块且已登记）
mk_spec t-badmod
sed -i 's#docs/architecture/modules/example-export.md#docs/architecture/modules/nonexistent.md#' docs/specs/active/t-badmod/design.md
expect_fail "G3 拒绝引用不存在的模块文档" "不存在" bash scripts/ai-gate.sh check t-badmod g3
mk_spec t-unreg
sed -i 's#docs/architecture/modules/example-export.md#docs/architecture/modules/unregistered-export.md#' docs/specs/active/t-unreg/design.md
expect_fail "G3 拒绝未在 00-INDEX 登记的模块" "登记" bash scripts/ai-gate.sh check t-unreg g3
mk_spec t-noboundary
sed -i '/^- 边界样本：/d' docs/specs/active/t-noboundary/design.md
expect_fail "②③的 G3 拒绝缺少边界样本" "边界样本" bash scripts/ai-gate.sh check t-noboundary g3
printf '%s\n' '- 边界样本：无' >>docs/specs/active/t-noboundary/design.md
expect_fail "②③的 G3 拒绝占位边界样本" "边界样本" bash scripts/ai-gate.sh check t-noboundary g3

# 新格式追溯链；上面的旧格式夹具继续验证兼容性。
mk_spec t-trace
sed -i '/WHEN 用户点击导出/i\- REQ-01：WHEN 用户点击导出，THE SYSTEM SHALL 生成任务。' docs/specs/active/t-trace/requirements.md
sed -i '/^# 技术架构与接口设计/a\- 追溯版本：1' docs/specs/active/t-trace/design.md
sed -i '/^## 2. 实现顺序/i\### 1.1 需求覆盖矩阵\n| 来源 ID | 原文锚点 | 设计落点 | 验证 |\n| :-- | :-- | :-- | :-- |\n| REQ-01 | requirements.md §2 上限原文 | §2 步骤 | AC-01 |\n| AC-01 | requirements.md §3 | §2 步骤 | 自检 |\n' docs/specs/active/t-trace/design.md
sed -i '/^# 原子执行队列/a\- 追溯版本：1' docs/specs/active/t-trace/tasks.md
sed -i '/^- \[x\] Task 1:/a\  - 对应需求 / 验收：REQ-01 / AC-01\n  - 对应设计：design.md §2' docs/specs/active/t-trace/tasks.md
sed -i '/^- \[x\] Task 2:/a\  - 对应需求 / 验收：REQ-01 / AC-01\n  - 对应设计：design.md §2' docs/specs/active/t-trace/tasks.md
expect_ok "新 Spec 完整追溯矩阵通过 G3" bash scripts/ai-gate.sh check t-trace g3
expect_ok "新 Spec 任务引用设计通过 G4" bash scripts/ai-gate.sh check t-trace g4
cp docs/specs/active/t-trace/tasks.md "$TMP/trace-tasks.bak"
sed -i 's#REQ-01 / AC-01#REQ-999 / AC-01#g' docs/specs/active/t-trace/tasks.md
expect_fail "G4 拒绝不存在的需求编号" "REQ-999" bash scripts/ai-gate.sh check t-trace g4
cp "$TMP/trace-tasks.bak" docs/specs/active/t-trace/tasks.md
sed -i 's#design.md §2#design.md §9#g' docs/specs/active/t-trace/tasks.md
expect_fail "G4 拒绝不存在的设计章节" "§9" bash scripts/ai-gate.sh check t-trace g4
cp "$TMP/trace-tasks.bak" docs/specs/active/t-trace/tasks.md
sed -i 's#REQ-01 / AC-01#REQ-01#g' docs/specs/active/t-trace/tasks.md
expect_fail "G4 拒绝需求未被任务承接" "AC-01" bash scripts/ai-gate.sh check t-trace g4
cp "$TMP/trace-tasks.bak" docs/specs/active/t-trace/tasks.md
sed -i '/^- 追溯版本：1/d' docs/specs/active/t-trace/design.md
expect_fail "G3 拒绝新 Spec 漏标记" "追溯版本" bash scripts/ai-gate.sh check t-trace g3
sed -i '/^# 技术架构与接口设计/a\- 追溯版本：1' docs/specs/active/t-trace/design.md
sed -i '/| AC-01 | requirements.md §3 | §2 步骤 | 自检 |/d' docs/specs/active/t-trace/design.md
expect_fail "G3 拒绝遗漏 AC 映射" "遗漏 AC-01" bash scripts/ai-gate.sh check t-trace g3
sed -i '/| REQ-01 |/a\| AC-01 | requirements.md §3 | §2 步骤 | 自检 |' docs/specs/active/t-trace/design.md
sed -i '/对应设计：design.md §2/d' docs/specs/active/t-trace/tasks.md
expect_fail "G4 拒绝任务缺设计章节" "任务与需求编号或设计章节不一致" bash scripts/ai-gate.sh check t-trace g4
expect_fail "G5 拒绝缺需求追溯审查结论" "需求追溯核对" bash scripts/ai-gate.sh check t-trace g5
cat >>docs/specs/active/t-trace/review.md <<'MD'

## 需求追溯与项目知识
- 需求追溯核对：REQ-01 与 AC-01 均落在设计 §2；上限已核对。
- 知识检索：export 模块无相关卡，已读模块文档。
- AI 协作文件审查：本次 diff 无此类文件。
- 审查范围限制：无。
MD
expect_ok "G5 接受有范围和知识结论的审查" bash scripts/ai-gate.sh check t-trace g5

section "3. 好样例必须通过 G1~G5"
mk_spec t-good
expect_ok "G1 通过" bash scripts/ai-gate.sh pass t-good g1
expect_ok "G2 通过" bash scripts/ai-gate.sh pass t-good g2
expect_ok "G3 通过" bash scripts/ai-gate.sh pass t-good g3
expect_ok "G4 通过（可交接摘要对应当前代码且 checks≥1）" bash scripts/ai-gate.sh pass t-good g4
expect_ok "G5 通过（审查者 + 未参与实现）" bash scripts/ai-gate.sh pass t-good g5
expect_out "status 能渲染下一门" "下一门" bash scripts/ai-gate.sh status t-good
expect_out "metrics 从门记录派生耗时" "g3 → g4:" bash scripts/ai-gate.sh metrics t-good
expect_ok "G6 通过（acceptance.md 留痕齐全）" bash scripts/ai-gate.sh check t-good g6
mv docs/specs/active/t-good/acceptance.md "$TMP/acc.bak"
expect_fail "G6 拒绝缺少 acceptance.md" "acceptance.md" bash scripts/ai-gate.sh check t-good g6
mv "$TMP/acc.bak" docs/specs/active/t-good/acceptance.md
sed -i 's/^- 冒烟或 E2E 证据：.*/- 冒烟或 E2E 证据：<待填写>/' docs/specs/active/t-good/acceptance.md
expect_fail "G6 拒绝缺少客观证据" "冒烟 / E2E" bash scripts/ai-gate.sh check t-good g6
sed -i 's/^- 冒烟或 E2E 证据：.*/- 冒烟或 E2E 证据：verification.md 的两项检查通过/' docs/specs/active/t-good/acceptance.md
sed -i 's/^- 对照 AC 的检查结果：.*/- 对照 AC 的检查结果：未检查/' docs/specs/active/t-good/acceptance.md
expect_fail "G6 拒绝未检查的 AC" "AC 核验摘要" bash scripts/ai-gate.sh check t-good g6
sed -i 's/^- 对照 AC 的检查结果：.*/- 对照 AC 的检查结果：AC-01 通过，见 verification.md/' docs/specs/active/t-good/acceptance.md
mk_spec t-multi-ac
sed -i '/| AC-01 |/a | AC-02 | 失败处理 | 拒绝无权限请求 | 泄漏数据 | 自动化检查 |' docs/specs/active/t-multi-ac/requirements.md
for g in g1 g2 g3 g4 g5; do bash scripts/ai-gate.sh pass t-multi-ac "$g" >/dev/null || exit 1; done
expect_fail "G6 拒绝遗漏第二条 AC" "AC-02" bash scripts/ai-gate.sh check t-multi-ac g6
printf '%s\n' '- AC-02：通过，见权限自动化检查' >>docs/specs/active/t-multi-ac/acceptance.md
expect_ok "G6 要求逐条 AC 均有证据" bash scripts/ai-gate.sh check t-multi-ac g6
sed -i '/^- 人工决定：/d' docs/specs/active/t-good/acceptance.md
expect_fail "②的 G6 拒绝缺少人的决定" "人的明确通过决定" bash scripts/ai-gate.sh check t-good g6
printf '%s\n' '- 人工决定：通过' >>docs/specs/active/t-good/acceptance.md
sed -i 's/^- 决策来源：.*/- 决策来源：<待填写>/' docs/specs/active/t-good/acceptance.md
expect_fail "②的 G6 拒绝占位决策来源" "决策来源" bash scripts/ai-gate.sh check t-good g6
sed -i 's/^- 决策来源：.*/- 决策来源：测试用例中的模拟对话决定/' docs/specs/active/t-good/acceptance.md
mk_spec t-auto
sed -i 's/②人机协同/①低风险小改动/' docs/specs/active/t-auto/requirements.md
sed -i '/^- 人工决策人：/d; /^- 人工决定：/d; /^- 决策来源：/d' docs/specs/active/t-auto/acceptance.md
for g in g1 g2 g3 g4 g5; do bash scripts/ai-gate.sh pass t-auto "$g" >/dev/null || exit 1; done
expect_ok "①有证据可由 Agent 推进 G6" bash scripts/ai-gate.sh pass t-auto g6
mk_spec t-delegated
for g in g1 g2 g3 g4 g5; do bash scripts/ai-gate.sh pass t-delegated "$g" >/dev/null || exit 1; done
sed -i 's/^- 人工决定：.*/- 人工决定：预先授权/' docs/specs/active/t-delegated/acceptance.md
sed -i 's#^- 需人判断的风险 / 遗留：.*#- 需人判断的风险 / 遗留：无#' docs/specs/active/t-delegated/acceptance.md
printf '%s\n' '- 验收方式：预授权委托' >>docs/specs/active/t-delegated/acceptance.md
expect_fail "G6 拒绝无 G3 授权的委托" "缺少 G3 明确授权" bash scripts/ai-gate.sh check t-delegated g6
add_delegation() {
  local design="$1"
  awk '{ print; if ($0 ~ /^- 人工前置决策：/) {
    print "- 条件委托决策人：运营负责人"
    print "- 条件委托来源：模拟对话"
    print "- 条件委托范围：仅 AC 全通过、G5 通过且无新增重大风险"
    print "- 条件委托结论：同意"
  }}' "$design" >"$design.tmp"
  mv "$design.tmp" "$design"
}
add_delegation docs/specs/active/t-delegated/design.md
expect_fail "G6 拒绝 G3 后补写的委托" "授权快照不一致" bash scripts/ai-gate.sh check t-delegated g6
bash scripts/ai-gate.sh reset t-delegated g3 --reason '测试 G3 重新确认委托' >/dev/null || exit 1
for g in g3 g4 g5; do bash scripts/ai-gate.sh pass t-delegated "$g" >/dev/null || exit 1; done
expect_ok "G6 接受 G3 明确限定范围的委托" bash scripts/ai-gate.sh check t-delegated g6
sed -i 's#^- 需人判断的风险 / 遗留：无#- 需人判断的风险 / 遗留：出现新增重大风险#' docs/specs/active/t-delegated/acceptance.md
expect_fail "G6 拒绝委托后的新增重大风险" "仍有需人判断的风险" bash scripts/ai-gate.sh check t-delegated g6
mk_spec t-denied-delegation
add_delegation docs/specs/active/t-denied-delegation/design.md
sed -i 's/^- 条件委托结论：同意/- 条件委托结论：不同意/' docs/specs/active/t-denied-delegation/design.md
expect_fail "G3 拒绝不同意的委托" "明确「同意」" bash scripts/ai-gate.sh check t-denied-delegation g3
mk_spec t-empty-delegation-source
add_delegation docs/specs/active/t-empty-delegation-source/design.md
sed -i 's/^- 条件委托来源：模拟对话/- 条件委托来源：/' docs/specs/active/t-empty-delegation-source/design.md
expect_fail "G3 拒绝空来源的委托" "非空决策人和来源" bash scripts/ai-gate.sh check t-empty-delegation-source g3

section "4. 验证摘要必须有目标、真实检查和当前代码状态"
mk_spec t-fake-hand
sed -i 's/^- result: PASS/- result: FAIL/' docs/specs/active/t-fake-hand/verification.md
expect_fail "G4 拒绝失败摘要" "未通过" bash scripts/ai-gate.sh check t-fake-hand g4

mk_spec t-zero
sed -i 's/^- checks: 2/- checks: 0/' docs/specs/active/t-zero/verification.md
expect_fail "G4 拒绝 0 项检查的 PASS" "0 项检查" bash scripts/ai-gate.sh check t-zero g4

mk_spec t-notarget
sed -i '/^- target:/d' docs/specs/active/t-notarget/verification.md
expect_fail "G4 拒绝缺少目标的摘要" "目标文件" bash scripts/ai-gate.sh check t-notarget g4

mk_spec t-stale
printf '// changed after verify\n' >>src/export/service.ts
expect_fail "G4 拒绝代码变化后的过期摘要" "过期" bash scripts/ai-gate.sh check t-stale g4
sed -i '$d' src/export/service.ts

expect_fail "多个活跃 Spec 必须显式选择" "显式指定" bash scripts/ai-verify.sh src/export/service.ts
expect_fail "ai-verify 拒绝路径别名 Spec" "无效 Spec" bash scripts/ai-verify.sh --spec .. src/export/service.ts
expect_fail "正式验证拒绝会移动的 Spec 文档目标" "流程文件" bash scripts/ai-verify.sh --spec t-good docs/specs/active/t-good/requirements.md
mkdir -p docs
printf '# Metrics\n' >docs/metrics.md
expect_fail "正式验证拒绝归档时会更新的度量目标" "流程文件" bash scripts/ai-verify.sh --spec t-good ./docs/metrics.md
expect_fail "验证拒绝重复分隔符绕过流程目标限制" "规范化项目路径" bash scripts/ai-verify.sh --spec t-good docs//metrics.md
expect_fail "验证拒绝中间点目录绕过流程目标限制" "规范化项目路径" bash scripts/ai-verify.sh --spec t-good docs/./specs/active/t-good/requirements.md
expect_out "owner 接手快照显示验证摘要" "可交接验证摘要" bash scripts/ai-resume.sh owner t-good
expect_out "owner 接手提示任务池下一步" "任务池下一步" bash scripts/ai-resume.sh owner t-good
expect_fail "旧式接手命令给迁移提示" "旧式" bash scripts/ai-resume.sh t-good
expect_fail "接手命令必须指定角色" "用法" bash scripts/ai-resume.sh
expect_fail "接手拒绝未知角色" "未知角色" bash scripts/ai-resume.sh observer t-good
mk_spec t-worker
cat >docs/specs/active/t-worker/tasks.md <<'MD'
## 2. 原子任务序列
- [ ] **Task 1：限定文件**
  - 涉及文件：`src/export/service.ts`
  - 对应设计：design.md §2
- [ ] **Task 2：另一个任务**
  - 涉及文件：`src/export/other.ts`

## 4. WIP
- 本段不属于 Task 2。
MD
expect_out "worker 只输出指定任务" "限定文件" bash scripts/ai-resume.sh worker t-worker 1
worker_out=$(bash scripts/ai-resume.sh worker t-worker 1)
if printf '%s' "$worker_out" | grep -q '另一个任务'; then ng_msg "worker 混入其他任务"; else ok_msg "worker 未混入其他任务"; fi
expect_fail "worker 拒绝缺失 Task" "找不到 Task" bash scripts/ai-resume.sh worker t-worker 9
mk_spec t-worker-no-boundary
cat >docs/specs/active/t-worker-no-boundary/tasks.md <<'MD'
## 2. 原子任务序列
- [ ] **Task 1：缺少文件边界**
  - 对应设计：design.md §2
MD
expect_fail "worker 拒绝缺失任务边界" "涉及文件" bash scripts/ai-resume.sh worker t-worker-no-boundary 1
cat >docs/specs/active/t-worker-no-boundary/tasks.md <<'MD'
## 2. 原子任务序列
- [ ] Task 1: 旧式普通标题
  - 涉及文件：`src/export/service.ts`
MD
expect_out "worker 接受旧 Spec 的普通 Task 标题" "旧式普通标题" bash scripts/ai-resume.sh worker t-worker-no-boundary 1
mk_spec t-worker-collision
cat >docs/specs/active/t-worker-collision/tasks.md <<'MD'
## 2. 原子任务序列
- [ ] Task 2: follow Task 1: migration
  - 涉及文件：`src/export/other.ts`
MD
expect_fail "worker 不把标题正文的 Task 1 当成任务编号" "找不到 Task 1" bash scripts/ai-resume.sh worker t-worker-collision 1
mk_spec t-real-verify
printf "CUSTOM_CHECK='test -f \"\$TARGET_FILE\"'\n" >harness/verify.conf
expect_ok "真实 ai-verify 为指定 Spec 生成摘要" bash scripts/ai-verify.sh --spec t-real-verify src/export/service.ts
file_has "真实验证摘要记入 PASS" docs/specs/active/t-real-verify/verification.md "- result: PASS"
expect_ok "G4 接受真实生成的摘要" bash scripts/ai-gate.sh check t-real-verify g4
cp docs/specs/active/t-real-verify/verification.md "$TMP/formal-summary"
printf "QUICK_CHECK='test -f \"\$TARGET_FILE\"'\n" >>harness/verify.conf
expect_ok "quick 执行真实检查" bash scripts/ai-verify.sh --quick --spec t-real-verify src/export/service.ts
if cmp -s "$TMP/formal-summary" docs/specs/active/t-real-verify/verification.md; then ok_msg "quick 不覆盖正式摘要"; else ng_msg "quick 覆盖了正式摘要"; fi
rm -f harness/verify.conf
expect_fail "quick 无真实检查时拒绝" "未执行任何真实检查" bash scripts/ai-verify.sh --quick --spec t-real-verify src/export/service.ts

GIT_SB="$TMP/git-state"
mkdir -p "$GIT_SB/scripts" "$GIT_SB/docs/specs/active/demo"
cp scripts/ai-state-id.sh "$GIT_SB/scripts/"
cp scripts/ai-config.sh "$GIT_SB/scripts/"
printf 'one\n' >"$GIT_SB/source.txt"
printf 'two\n' >"$GIT_SB/other.txt"
printf '{"name":"selftest"}\n' >"$GIT_SB/package.json"
(
  cd "$GIT_SB" || exit 1
  git init -q && git add . && git -c user.name=selftest -c user.email=selftest@example.invalid commit -qm initial
)
before=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh source.txt)
printf 'changed\n' >>"$GIT_SB/other.txt"
after=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh source.txt)
if [ "$before" != "$after" ]; then ok_msg "Git 指纹识别非目标代码文件变化"; else ng_msg "Git 指纹漏掉非目标代码文件变化"; fi
(
  cd "$GIT_SB" || exit 1
  git add other.txt
)
staged=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh source.txt)
(
  cd "$GIT_SB" || exit 1
  git -c user.name=selftest -c user.email=selftest@example.invalid commit -qm changed
)
committed=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh source.txt)
if [ "$staged" = "$committed" ]; then ok_msg "Git 指纹在暂存到提交后稳定"; else ng_msg "Git 指纹在提交后无内容变化仍过期"; fi
printf 'new\n' >"$GIT_SB/new.txt"
(
  cd "$GIT_SB" || exit 1
  git add new.txt
)
staged_new=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh source.txt)
(
  cd "$GIT_SB" || exit 1
  git -c user.name=selftest -c user.email=selftest@example.invalid commit -qm added
)
committed_new=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh source.txt)
if [ "$staged_new" = "$committed_new" ]; then ok_msg "新文件暂存到提交后指纹稳定"; else ng_msg "新文件提交后指纹过期"; fi
mkdir -p "$GIT_SB/docs"
metrics_before=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh source.txt)
printf 'delivery result\n' >"$GIT_SB/docs/metrics.md"
metrics_after=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh source.txt)
if [ "$metrics_before" = "$metrics_after" ]; then ok_msg "交付度量不使代码指纹过期"; else ng_msg "交付度量错误地使代码指纹过期"; fi
mkdir -p "$GIT_SB/docs/specs/active/one" "$GIT_SB/docs/specs/active/two" "$GIT_SB/docs/specs/active/three"
printf '## 4. 影响面与涉及文件清单\n- 指纹范围确认：已核对验证命令及其脚本、配置、测试依赖\n- `source.txt`：本任务\n' >"$GIT_SB/docs/specs/active/one/design.md"
printf '## 4. 影响面与涉及文件清单\n- 指纹范围确认：已核对验证命令及其脚本、配置、测试依赖\n- `other.txt`：另一任务\n' >"$GIT_SB/docs/specs/active/two/design.md"
printf '## 4. 影响面与涉及文件清单\n- 指纹范围确认：已核对验证命令及其脚本、配置、测试依赖\n- `scripts/ai-config.sh`：第三个任务\n- `package.json`：第三个任务\n' >"$GIT_SB/docs/specs/active/three/design.md"
base=$(cd "$GIT_SB" && git rev-parse HEAD)
printf 'g3\tagent\t2026-10-20T00:00:00Z\t%s\n' "$base" >"$GIT_SB/docs/specs/active/one/.gates"
printf 'g3\tagent\t2026-10-20T00:00:00Z\t%s\n' "$base" >"$GIT_SB/docs/specs/active/two/.gates"
printf 'g3\tagent\t2026-10-20T00:00:00Z\t%s\n' "$base" >"$GIT_SB/docs/specs/active/three/.gates"
scope_before=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh --spec one source.txt)
printf 'other spec change\n' >>"$GIT_SB/other.txt"
scope_other=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh --spec one source.txt)
if [ "$scope_before" = "$scope_other" ]; then ok_msg "其他活跃 Spec 的文件改动不使本 Spec 过期"; else ng_msg "其他 Spec 的改动误使本 Spec 过期"; fi
printf '\n# verification dependency changed\n' >>"$GIT_SB/scripts/ai-config.sh"
scope_dependency=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh --spec one source.txt)
if [ "$scope_other" != "$scope_dependency" ]; then ok_msg "其他 Spec 修改验证器依赖仍使本 Spec 过期"; else ng_msg "验证器依赖被错误豁免"; fi
(cd "$GIT_SB" && git checkout -- scripts/ai-config.sh)
printf '\n' >>"$GIT_SB/package.json"
scope_toolchain=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh --spec one source.txt)
if [ "$scope_other" != "$scope_toolchain" ]; then ok_msg "其他 Spec 修改工具链声明仍使本 Spec 过期"; else ng_msg "工具链声明被错误豁免"; fi
(cd "$GIT_SB" && git checkout -- package.json)
printf 'own change\n' >>"$GIT_SB/source.txt"
scope_own=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh --spec one source.txt)
if [ "$scope_other" != "$scope_own" ]; then ok_msg "本 Spec 文件改动使指纹过期"; else ng_msg "本 Spec 文件改动未使指纹过期"; fi
sed -i 's/`source.txt`：本任务/`source.txt`、`other.txt`：本任务/' "$GIT_SB/docs/specs/active/one/design.md"
scope_multi_before=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh --spec one source.txt)
printf 'multi path change\n' >>"$GIT_SB/other.txt"
scope_multi_after=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh --spec one source.txt)
if [ "$scope_multi_before" != "$scope_multi_after" ]; then ok_msg "多反引号清单回退全仓指纹"; else ng_msg "多反引号清单漏掉第二个路径"; fi
sed -i 's/`source.txt`、`other.txt`：本任务/`source.txt`：本任务/' "$GIT_SB/docs/specs/active/one/design.md"
printf 'unclaimed\n' >"$GIT_SB/unclaimed.txt"
scope_unclaimed=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh --spec one source.txt)
if [ "$scope_own" != "$scope_unclaimed" ]; then ok_msg "未归属改动触发全仓保守指纹"; else ng_msg "未归属改动被 scoped 指纹忽略"; fi
sed -i 's/`source.txt`/`*.txt`/' "$GIT_SB/docs/specs/active/one/design.md"
scope_glob_before=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh --spec one source.txt)
printf 'changed again\n' >>"$GIT_SB/other.txt"
scope_glob_after=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh --spec one source.txt)
if [ "$scope_glob_before" != "$scope_glob_after" ]; then ok_msg "通配清单回退全仓指纹"; else ng_msg "通配清单错误启用 scoped 指纹"; fi
mkdir -p "$GIT_SB/docs/specs/active/legacy"
printf '## 4. 影响面与涉及文件清单\n- source.txt：旧格式\n' >"$GIT_SB/docs/specs/active/legacy/design.md"
legacy_before=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh --spec legacy source.txt)
printf 'legacy unrelated\n' >>"$GIT_SB/other.txt"
legacy_after=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh --spec legacy source.txt)
if [ "$legacy_before" != "$legacy_after" ]; then ok_msg "旧 Spec 无精确清单时保守全仓"; else ng_msg "旧 Spec 被错误缩小指纹范围"; fi

RESUME_SB="$TMP/resume-review"
mkdir -p "$RESUME_SB/scripts" "$RESUME_SB/docs/specs/active/demo"
cp "$ROOT/scripts/ai-resume.sh" "$ROOT/scripts/ai-state-id.sh" "$RESUME_SB/scripts/"
printf 'initial\n' >"$RESUME_SB/source.txt"
printf '原始需求与 AC\n' >"$RESUME_SB/docs/specs/active/demo/requirements.md"
printf '## 4. 影响面\n' >"$RESUME_SB/docs/specs/active/demo/design.md"
printf '## 2. Task 1\n' >"$RESUME_SB/docs/specs/active/demo/tasks.md"
(
  cd "$RESUME_SB" || exit 1
  git init -q && git add scripts source.txt && git -c user.name=selftest -c user.email=selftest@example.invalid commit -qm initial
)
review_base=$(cd "$RESUME_SB" && git rev-parse HEAD)
printf 'changed\n' >>"$RESUME_SB/source.txt"
review_state=$(cd "$RESUME_SB" && bash scripts/ai-state-id.sh --spec demo source.txt)
cat >"$RESUME_SB/docs/specs/active/demo/verification.md" <<MD
- target: source.txt
- result: PASS
- state: $review_state
MD
expect_fail "review 拒绝无效基准" "无法解析基准" bash -c 'cd "$1" && bash scripts/ai-resume.sh review demo missing-ref' _ "$RESUME_SB"
empty_tree=$(cd "$RESUME_SB" && git hash-object -t tree /dev/null)
unrelated_base=$(cd "$RESUME_SB" && printf 'unrelated\n' | git -c user.name=selftest -c user.email=selftest@example.invalid commit-tree "$empty_tree")
expect_fail "review 拒绝无共同历史的基准" "不是当前 HEAD 的祖先" bash -c 'cd "$1" && bash scripts/ai-resume.sh review demo "$2"' _ "$RESUME_SB" "$unrelated_base"
expect_out "review 给出原始证据与完整 diff 命令" "git diff $review_base...HEAD" bash -c 'cd "$1" && bash scripts/ai-resume.sh review demo "$2"' _ "$RESUME_SB" "$review_base"
rm "$RESUME_SB/docs/specs/active/demo/requirements.md"
expect_fail "review 拒绝缺失原始需求" "缺少审查原件" bash -c 'cd "$1" && bash scripts/ai-resume.sh review demo "$2"' _ "$RESUME_SB" "$review_base"
printf '原始需求与 AC\n' >"$RESUME_SB/docs/specs/active/demo/requirements.md"
printf 'stale\n' >>"$RESUME_SB/source.txt"
expect_fail "review 拒绝过期验证摘要" "过期" bash -c 'cd "$1" && bash scripts/ai-resume.sh review demo "$2"' _ "$RESUME_SB" "$review_base"
(
  cd "$RESUME_SB" || exit 1
  git checkout -- source.txt
  review_state=$(bash scripts/ai-state-id.sh --spec demo source.txt)
  sed -i "s/^- state: .*/- state: $review_state/" docs/specs/active/demo/verification.md
  git add . && git -c user.name=selftest -c user.email=selftest@example.invalid commit -qm no-diff
)
expect_fail "review 拒绝空 diff" "没有可审查的变更" bash -c 'cd "$1" && bash scripts/ai-resume.sh review demo HEAD' _ "$RESUME_SB"

section "5. 独立 CR 证据链（自己审自己不留痕 = 未审查）"
mk_spec t-selfreview
sed -i '/未参与实现/d' docs/specs/active/t-selfreview/review.md
expect_fail "G5 拒绝未声明「未参与实现」" "未参与实现" bash scripts/ai-gate.sh check t-selfreview g5
mk_spec t-placeholder
sed -i 's/\*\*审查者\*\*：.*/**审查者**：<独立上下文标识>/' docs/specs/active/t-placeholder/review.md
expect_fail "G5 拒绝模板占位的审查者" "审查者" bash scripts/ai-gate.sh check t-placeholder g5

# CR 修复包络（超过 4 轮必须转人工，禁止无限自我修复）
mk_spec t-cr5
sed -i 's/^- \*\*CR 轮次\*\*：.*/- **CR 轮次**：5 \/ 4/' docs/specs/active/t-cr5/review.md
expect_fail "G5 拒绝 CR 轮次超上限" "上限" bash scripts/ai-gate.sh check t-cr5 g5
mk_spec t-nocr
sed -i '/CR 轮次/d' docs/specs/active/t-nocr/review.md
expect_fail "G5 拒绝缺少 CR 轮次" "CR 轮次" bash scripts/ai-gate.sh check t-nocr g5
mk_spec t-stalereview
for g in g1 g2 g3 g4; do bash scripts/ai-gate.sh pass t-stalereview "$g" >/dev/null || exit 1; done
sed -i 's/^- 审查状态：.*/- 审查状态：old-state/' docs/specs/active/t-stalereview/review.md
expect_fail "G5 拒绝与验证摘要不符的旧审查" "审查状态" bash scripts/ai-gate.sh check t-stalereview g5

section "6. Agent 记录与人工身份标记的本地防误操作"
call_g6_agent() { bash scripts/ai-gate.sh pass t-good g6; }
call_g6_human() { bash scripts/ai-gate.sh pass t-good g6 --by human </dev/null; }
call_baseline() { bash scripts/ai-gate.sh baseline </dev/null; }
expect_ok "②有人决定与客观证据后可由 Agent 记录 G6" call_g6_agent
expect_fail "G6 拒绝非 TTY 的 --by human" "TTY" call_g6_human
expect_fail "baseline 拒绝非 TTY 确认" "TTY" call_baseline

section "7. 红线漂移必须阻断推进"
printf '\n# tampered by selftest\n' >>harness/redlines.conf
expect_fail "红线漂移时 pass 被阻断" "漂移" bash scripts/ai-gate.sh pass t-good g1
expect_out "status 报出红线漂移" "漂移" bash scripts/ai-gate.sh status t-good
cp "$TMP/redlines.fixture" harness/redlines.conf
expect_out "恢复红线后基线重新一致" "一致" bash scripts/ai-gate.sh status t-good

section "8. 门禁回退（reset）"
mk_spec t-reset
bash scripts/ai-gate.sh pass t-reset g1 >/dev/null 2>&1
bash scripts/ai-gate.sh pass t-reset g2 >/dev/null 2>&1
bash scripts/ai-gate.sh pass t-reset g3 >/dev/null 2>&1
expect_ok "reset 使 g2 及之后失效" bash scripts/ai-gate.sh reset t-reset g2 --reason "需求变更"
file_lacks ".gates 里已删除 g2" docs/specs/active/t-reset/.gates "g2"
file_lacks ".gates 里已删除 g3" docs/specs/active/t-reset/.gates "g3"
file_has ".gates 里保留 g1" docs/specs/active/t-reset/.gates "g1"
expect_fail "reset 后 pass g3 被前置门拦住" "前置门 g2 未通过" bash scripts/ai-gate.sh pass t-reset g3
expect_fail "未知门被拒" "未知门" bash scripts/ai-gate.sh pass t-reset g9
expect_fail "未知 spec 被拒" "找不到 spec" bash scripts/ai-gate.sh pass no-such-feat g1

section "9. 零检查 = 未验证（本地可信最低门槛）"
mkdir -p src && : >src/x.ts
expect_fail "无项目工具链时 ai-verify 必须失败" "未执行任何真实检查" bash scripts/ai-verify.sh --spec t-good src/x.ts

section "10. 成本包络：连续失败计数与黄卡"
ONLY="$TMP/only"
mkdir -p "$ONLY/scripts" "$ONLY/harness" "$ONLY/docs/specs/active/only/reports"
cp -r "$ROOT/scripts/." "$ONLY/scripts/"
cp "$TMP/redlines.fixture" "$ONLY/harness/redlines.conf"
printf 'CUSTOM_CHECK="false"\n' >"$ONLY/harness/verify.conf"
: >"$ONLY/src.ts"
(
  cd "$ONLY" || exit 1
  bash scripts/ai-verify.sh --spec only src.ts >/dev/null 2>&1
  bash scripts/ai-verify.sh --spec only src.ts >/dev/null 2>&1
  bash scripts/ai-verify.sh --spec only src.ts >out3 2>&1
)
n=$(tr -dc '0-9' <"$ONLY/docs/specs/active/only/.attempts" 2>/dev/null)
if [ "${n:-}" = "3" ]; then ok_msg "连续失败计数 = 3"; else ng_msg "连续失败计数应为 3，实际 ${n:-空}"; fi
if grep -q '黄卡' "$ONLY/out3" 2>/dev/null; then ok_msg "第 3 次失败输出黄卡"; else ng_msg "第 3 次失败未输出黄卡"; fi

# ---------------------------------------------------------------- 知识飞轮 ----
section "11. 知识卡体检与前置强注入"
mkdir -p .knowledge/cards
cat >.knowledge/cards/K-0001.md <<'MD'
# K-0001 导出任务幂等
- **类型**：技术方案
- **模块**：export
- **置信度**：0.7
- **创建日期**：2026-10-20
- **最近复核**：2026-10-20
- **复核期限**：2099-12-31
- **标签**：#自动沉淀
- **关联路径**：src/export/
MD
cat >.knowledge/INDEX.md <<'MD'
# 知识索引（Index）
| ID | 类型 | 模块 | 置信度 | 复核期限 | 结论摘要 |
| :-- | :-- | :-- | :-- | :-- | :-- |
| K-0001 | 技术方案 | export | 0.7 | 2099-12-31 | 导出任务幂等 |
MD
expect_out "knowledge check 索引与卡片一致" "一致" bash scripts/ai-knowledge.sh check
expect_out "suggest 按模块列有效卡" "K-0001" bash scripts/ai-knowledge.sh suggest export
expect_out "impact 按变更路径提示复核" "K-0001" bash scripts/ai-knowledge.sh impact src/export/service.ts

mk_spec t-inj
sed -i 's/^- 注入知识：.*/- 注入知识：`K-0001`/' docs/specs/active/t-inj/tasks.md
expect_ok "G4 通过：注入的知识卡存在" bash scripts/ai-gate.sh check t-inj g4
sed -i 's/`K-0001`/`K-0001`, `K-0001`/' docs/specs/active/t-inj/tasks.md
for g in g1 g2 g3 g4; do bash scripts/ai-gate.sh pass t-inj "$g" >/dev/null || exit 1; done
sed -i 's/无相关卡片/无相关卡片（示例 K-0001）/' docs/specs/active/t-good/tasks.md
expect_out "usage 按 Spec 去重采用次数" "K-0001  1 个 Spec：t-inj" bash scripts/ai-knowledge.sh usage
mkdir -p docs/specs/archive/2026-10
mv docs/specs/active/t-inj docs/specs/archive/2026-10/
expect_out "usage 归档后仍计同一 Spec" "K-0001  1 个 Spec：t-inj" bash scripts/ai-knowledge.sh usage
mk_spec t-badcard
sed -i 's/^- 注入知识：.*/- 注入知识：`K-9999`/' docs/specs/active/t-badcard/tasks.md
expect_fail "G4 拒绝注入不存在的知识卡" "K-9999" bash scripts/ai-gate.sh check t-badcard g4
mk_spec t-noknow
sed -i '/^- 注入知识/d' docs/specs/active/t-noknow/tasks.md
expect_fail "G4 拒绝缺少注入知识行" "注入知识" bash scripts/ai-gate.sh check t-noknow g4
mk_spec t-nolookup
sed -i '/^- 知识检索：/d' docs/specs/active/t-nolookup/tasks.md
expect_fail "G4 拒绝无知识检索依据" "知识检索" bash scripts/ai-gate.sh check t-nolookup g4
mk_spec t-stalecard
sed -i 's/^- 注入知识：.*/- 注入知识：`K-0001`/' docs/specs/active/t-stalecard/tasks.md
sed -i 's/^- \*\*复核期限\*\*：.*/- **复核期限**：2000-01-01/' .knowledge/cards/K-0001.md
expect_fail "G4 拒绝过期知识卡" "复核期限" bash scripts/ai-gate.sh check t-stalecard g4
sed -i 's/^- \*\*复核期限\*\*：.*/- **复核期限**：2099-12-31/' .knowledge/cards/K-0001.md
printf '\n#待验证\n' >>.knowledge/cards/K-0001.md
expect_fail "G4 拒绝待验证知识卡" "待验证" bash scripts/ai-gate.sh check t-stalecard g4
sed -i '/^#待验证$/d' .knowledge/cards/K-0001.md

# 过期卡 → 清理候选（只提醒不失败）；非法置信度 → 硬失败
cat >.knowledge/cards/K-0002.md <<'MD'
# K-0002 过期卡
- **类型**：踩坑
- **模块**：export
- **置信度**：0.5
- **创建日期**：2026-10-20
- **最近复核**：2026-10-20
- **复核期限**：2000-01-01
- **标签**：#踩坑
MD
printf '| K-0002 | 踩坑 | export | 0.5 | 2000-01-01 | 过期卡 |\n' >>.knowledge/INDEX.md
expect_out "usage 列出未采用卡片" "K-0002  0 个 Spec（未采用）" bash scripts/ai-knowledge.sh usage
expect_out "ttl 列出清理候选" "清理候选" bash scripts/ai-knowledge.sh ttl
sed -i 's/^- \*\*置信度\*\*：0.5/- **置信度**：1.5/' .knowledge/cards/K-0002.md
expect_fail "knowledge check 拒绝置信度 >1" "置信度" bash scripts/ai-knowledge.sh check
sed -i 's/^- \*\*置信度\*\*：1.5/- **置信度**：0.5/' .knowledge/cards/K-0002.md
rm -f .knowledge/cards/K-0002.md
expect_fail "knowledge check 拒绝索引引用不存在卡片" "不存在" bash scripts/ai-knowledge.sh check
sed -i '/K-0002/d' .knowledge/INDEX.md
expect_out "删卡并删索引后恢复一致" "一致" bash scripts/ai-knowledge.sh check

# ---------------------------------------------------------- 单一配置来源 ----
section "12. 阈值只从项目配置读取"
cp harness/redlines.conf "$TMP/redlines.original"
sed -i 's/^FEASIBILITY_MIN=.*/FEASIBILITY_MIN=81/' harness/redlines.conf
mk_spec t-config-threshold
expect_fail "修改可行性阈值后 G1 使用新值" "81" bash scripts/ai-gate.sh check t-config-threshold g1
cp "$TMP/redlines.original" harness/redlines.conf
sed -i 's/^AGENTS_MAX_LINES=.*/AGENTS_MAX_LINES=17/' harness/redlines.conf
printf 'line\n%.0s' {1..18} >AGENTS.md
expect_fail "体积体检按项目配置的新上限拒绝" "硬上限 17 行" bash scripts/ai-check-bloat.sh
rm AGENTS.md
cp "$TMP/redlines.original" harness/redlines.conf
sed -i 's/^KNOWLEDGE_TTL_DAYS=.*/KNOWLEDGE_TTL_DAYS=29/' harness/redlines.conf
expect_out "知识保鲜显示项目配置的新期限" "TTL 29 天" bash scripts/ai-knowledge.sh ttl
cp "$TMP/redlines.original" harness/redlines.conf
sed -i '/^FEASIBILITY_MIN=/d' harness/redlines.conf
expect_fail "缺失必要配置键时 gate 拒绝" "FEASIBILITY_MIN" bash scripts/ai-gate.sh check t-config-threshold g1
cp "$TMP/redlines.original" harness/redlines.conf
sed -i 's/^VERIFY_MAX_SECONDS=.*/VERIFY_MAX_SECONDS=invalid/' harness/redlines.conf
expect_fail "非法验证预算时 verify 拒绝" "VERIFY_MAX_SECONDS" bash scripts/ai-verify.sh --spec t-config-threshold src/export/service.ts
cp "$TMP/redlines.original" harness/redlines.conf
sed -i 's/^AGENTS_MAX_LINES=.*/AGENTS_MAX_LINES=invalid/' harness/redlines.conf
expect_fail "非法体积预算时 bloat 拒绝" "AGENTS_MAX_LINES" bash scripts/ai-check-bloat.sh
cp "$TMP/redlines.original" harness/redlines.conf
sed -i 's/^AGENTS_MAX_LINES=.*/AGENTS_MAX_LINES=999999999999999999999999999/' harness/redlines.conf
expect_fail "超大整数预算时 bloat 拒绝" "整数范围" bash scripts/ai-check-bloat.sh
cp "$TMP/redlines.original" harness/redlines.conf
sed -i 's/^KNOWLEDGE_TTL_DAYS=.*/KNOWLEDGE_TTL_DAYS=invalid/' harness/redlines.conf
expect_fail "非法知识期限时 knowledge 拒绝" "KNOWLEDGE_TTL_DAYS" bash scripts/ai-knowledge.sh check
rm harness/redlines.conf
expect_fail "缺失项目配置时拒绝" "缺少配置" bash scripts/ai-gate.sh check t-config-threshold g1
cp "$TMP/redlines.original" harness/redlines.conf

# ---------------------------------------------------------------- 汇总 --------
section "13. 跨会话任务池"
POOL_SB="$TMP/task-pool"
mkdir -p "$POOL_SB/scripts" "$POOL_SB/docs/specs/archive"
cp "$ROOT/scripts/ai-task-pool.sh" "$ROOT/scripts/ai-new-spec.sh" "$POOL_SB/scripts/"
cp -r "$ROOT/docs/specs/_templates" "$POOL_SB/docs/specs/_templates"
cd "$POOL_SB" || exit 1
expect_out "空池 next 可用" "暂无待办" bash scripts/ai-task-pool.sh next
expect_fail "拒绝无效优先级" "优先级" bash scripts/ai-task-pool.sh add --priority P3 bad
expect_fail "拒绝空白原话" "不能为空" bash scripts/ai-task-pool.sh add "   "
expect_out "收集第一条需求" "T-000001" bash scripts/ai-task-pool.sh add "较晚处理"
expect_out "收集高优先级需求" "T-000002" bash scripts/ai-task-pool.sh add --priority P0 "先处理"
expect_out "默认按收录顺序选下一项" "下一项：T-000001" bash scripts/ai-task-pool.sh next
expect_out "下一项显示原始需求" "原始需求：较晚处理" bash scripts/ai-task-pool.sh next
expect_fail "拒绝指定不存在任务" "任务不存在" bash scripts/ai-task-pool.sh prefer T-000003
expect_out "人工指定下一项" "已指定 T-000002" bash scripts/ai-task-pool.sh prefer T-000002
expect_out "跨会话保留指定" "下一项：T-000002" bash scripts/ai-task-pool.sh next
file_has "指定选择已落盘" docs/task-pool/NEXT "T-000002"
expect_out "追加需求变更" "已追加" bash scripts/ai-task-pool.sh update T-000002 "加入边界"
expect_out "再次追加需求变更" "已追加" bash scripts/ai-task-pool.sh update T-000002 "再补一条"
expect_fail "拒绝空白补充" "不能为空" bash scripts/ai-task-pool.sh update T-000002 "   "
file_has "原话未被更新覆盖" docs/task-pool/T-000002.md "先处理"
file_has "补充已落盘" docs/task-pool/T-000002.md "加入边界"
file_has "第二次补充已落盘" docs/task-pool/T-000002.md "再补一条"
expect_fail "拒绝非法任务 ID" "ID 无效" bash scripts/ai-task-pool.sh update T-2 bad
sed -i 's/^- 优先级: P0$/- 优先级: P3/' docs/task-pool/T-000002.md
expect_fail "next 拒绝手工改坏的优先级" "优先级无效" bash scripts/ai-task-pool.sh next
expect_fail "start 拒绝手工改坏的优先级" "优先级无效" bash scripts/ai-task-pool.sh start T-000002 feat-invalid
sed -i 's/^- 优先级: P3$/- 优先级: P0/' docs/task-pool/T-000002.md
rm docs/specs/_templates/acceptance.md
expect_fail "建 Spec 缺模板时失败" "模板缺失" bash scripts/ai-task-pool.sh start T-000002 feat-broken
[ ! -e docs/specs/active/feat-broken ] && ok_msg "失败后无孤儿 Spec" || ng_msg "失败后留下孤儿 Spec"
file_has "失败后任务仍未关联" docs/task-pool/T-000002.md "- 关联 Spec: 无"
cp "$ROOT/docs/specs/_templates/acceptance.md" docs/specs/_templates/acceptance.md
cp docs/specs/_templates/requirements.md "$TMP/pool-requirements.original"
sed -i '/^- \*\*需求来源\*\*:/d' docs/specs/_templates/requirements.md
expect_fail "建 Spec 来源占位缺失时失败" "创建 Spec 失败" bash scripts/ai-task-pool.sh start T-000002 feat-broken-source
[ ! -e docs/specs/active/feat-broken-source ] && ok_msg "来源处理失败后无孤儿 Spec" || ng_msg "来源处理失败后留下孤儿 Spec"
cp "$TMP/pool-requirements.original" docs/specs/_templates/requirements.md
expect_out "从待办建 Spec" "已关联 feat-first" bash scripts/ai-task-pool.sh start T-000002 feat-first
[ ! -e docs/task-pool/NEXT ] && ok_msg "成功启动后清除一次性指定" || ng_msg "成功启动后仍有指定"
file_has "新 Spec 引用任务原件" docs/specs/active/feat-first/requirements.md "docs/task-pool/T-000002.md"
expect_out "活跃 Spec 优先续做" "续做活跃 Spec：feat-first" bash scripts/ai-task-pool.sh next
expect_fail "拒绝指定已开始任务" "不是未关联" bash scripts/ai-task-pool.sh prefer T-000002
expect_out "活跃期间可指定下项" "已指定 T-000001" bash scripts/ai-task-pool.sh prefer T-000001
expect_fail "拒绝重复领取" "不是未关联" bash scripts/ai-task-pool.sh start T-000002 feat-second
expect_fail "已有活跃 Spec 时拒绝启动下一项" "已有活跃 Spec" bash scripts/ai-task-pool.sh start T-000001 feat-second
mkdir -p docs/specs/archive/2026-10
mkdir docs/task-pool/.lock
expect_fail "归档遇任务池锁明确拒绝" "另一进程修改" bash scripts/ai-task-pool.sh archive feat-first
[ -d docs/specs/active/feat-first ] && ok_msg "锁冲突时活跃 Spec 未移动" || ng_msg "锁冲突误移动活跃 Spec"
rmdir docs/task-pool/.lock
expect_out "同锁归档活跃 Spec" "已归档 feat-first" bash scripts/ai-task-pool.sh archive feat-first
expect_out "归档后选下一项" "下一项：T-000001" bash scripts/ai-task-pool.sh next
expect_out "归档状态由 Spec 派生" "已归档" bash scripts/ai-task-pool.sh list
expect_out "补充另一个待办" "T-000003" bash scripts/ai-task-pool.sh add "临时插队"
expect_out "手动启动其他任务" "已关联 feat-other" bash scripts/ai-task-pool.sh start T-000003 feat-other
file_has "手动启动其他任务不清除指定" docs/task-pool/NEXT "T-000001"
expect_out "归档插队任务" "已归档 feat-other" bash scripts/ai-task-pool.sh archive feat-other
expect_out "同锁选择并启动指定任务" "已关联 feat-t-000001" bash scripts/ai-task-pool.sh start-next
[ ! -e docs/task-pool/NEXT ] && ok_msg "指定任务启动后清除指定" || ng_msg "指定任务启动后仍有指定"
mkdir docs/task-pool/.lock
expect_fail "并发写锁拒绝收集" "另一进程修改" bash scripts/ai-task-pool.sh add "冲突任务"
rmdir docs/task-pool/.lock

AUTO_SB="$TMP/task-pool-auto"
mkdir -p "$AUTO_SB/scripts" "$AUTO_SB/docs/specs/archive"
cp "$ROOT/scripts/ai-task-pool.sh" "$ROOT/scripts/ai-new-spec.sh" "$AUTO_SB/scripts/"
cp -r "$ROOT/docs/specs/_templates" "$AUTO_SB/docs/specs/_templates"
cd "$AUTO_SB" || exit 1
expect_out "空池自然语言收录并启动" "已关联 feat-t-000001" bash scripts/ai-task-pool.sh intake "第一条需求"
expect_out "活跃期间新需求只入队" "续做活跃 Spec：feat-t-000001" bash scripts/ai-task-pool.sh intake "第二条需求"
file_has "活跃期间新需求保留原话" docs/task-pool/T-000002.md "第二条需求"
mkdir -p docs/specs/archive/2026-10
expect_out "自动路由样本归档" "已归档 feat-t-000001" bash scripts/ai-task-pool.sh archive feat-t-000001
expect_out "已有待办时先启动旧任务" "已关联 feat-t-000002" bash scripts/ai-task-pool.sh intake "第三条需求"
file_has "较新需求仍待办" docs/task-pool/T-000003.md "- 关联 Spec: 无"
expect_out "旧待办完成后归档" "已归档 feat-t-000002" bash scripts/ai-task-pool.sh archive feat-t-000002
rm docs/specs/_templates/acceptance.md
expect_fail "自动启动失败仍提示已收录" "已收录" bash scripts/ai-task-pool.sh intake "第四条需求"
file_has "自动启动失败仍保留任务" docs/task-pool/T-000004.md "第四条需求"
file_has "自动启动失败不关联旧待办" docs/task-pool/T-000003.md "- 关联 Spec: 无"
cd "$SB" || exit 1

# ---------------------------------------------------------------- 汇总 --------
echo ""
printf '== %s: %ss ==\n' "$SECTION_NAME" "$((SECONDS - SECTION_START))"
echo "== 自检结果：$TOTAL 项断言，失败 $FAILED 项 =="
if [ "$FAILED" -ne 0 ]; then
  echo "❌ 门禁自检未通过：先修 scripts/ai-gate.sh 或 ai-verify.sh，再谈业务代码。"
  exit 1
fi
echo "🟢 门禁自检通过：该拒的拒了，该过的过了。"
