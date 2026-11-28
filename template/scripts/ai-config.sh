#!/usr/bin/env bash
# 供脚手架脚本 source；当前项目的 harness/redlines.conf 是阈值唯一来源。

ai_config_load() {
  local config="${1:-}" key value
  shift || return 1
  if [ ! -f "$config" ]; then
    printf '❌ 缺少配置 %s；请从脚手架模板补齐项目配置，勿使用隐含默认值\n' "$config" >&2
    return 1
  fi
  # 不继承宿主环境或先前命令留下的同名值。
  for key in "$@"; do unset "$key"; done
  # 配置由当前项目维护者管理；仅加载项目内的明确文件。
  . "$config" || { printf '❌ 无法读取配置 %s\n' "$config" >&2; return 1; }
  for key in "$@"; do
    value="${!key-}"
    [[ "$value" =~ ^[1-9][0-9]{0,8}$ ]] || { printf '❌ %s 的 %s 须为正整数\n' "$config" "$key" >&2; return 1; }
  done
}

# 多个工作区（git worktree）：一个工作区同一时间只做一个 Spec；任务池全仓库只有主工作区那一份。
wt_list() { # Git 的工作区清单。第一项不是工作区时不输出（主工作区是裸仓库、--separate-git-dir、子模块这类布局）：不认多个工作区，各工作区照旧各管各的
  local l m; l=$(git worktree list --porcelain 2>/dev/null) || return 0
  m=${l%%$'\n'*}; [[ $'\n'"$l"$'\n' == *$'\nbare\n'* ]] || [ ! -e "${m#worktree }/.git" ] || printf '%s\n' "$l"
}
worktrees() { wt_list | sed -n 's/^worktree //p'; } # 第一个是主工作区
main_wt() { # 在别的工作区里输出主工作区的目录；在主工作区或不在 Git 仓库里时没有输出
  [ "$(git rev-parse --git-dir 2>/dev/null)" = "$(git rev-parse --git-common-dir 2>/dev/null)" ] || worktrees | sed -n 1p
}
branch_wt() { # 检出了某个分支的工作区目录；目录已经不在的不算
  local w; w=$(wt_list | awk -v b="branch refs/heads/$1" '/^worktree /{w=substr($0,10)} $0==b{print w}')
  [ -n "$w" ] && [ -d "$w" ] && printf '%s\n' "$w"
}
own_specs() { # 当前工作区自己的活跃 Spec 目录：Spec 归启动它的工作区，挪到同名分支的工作区后归那个工作区
  local d m base="" me w
  m=$(main_wt); me=$(git branch --show-current 2>/dev/null)
  [ -z "$m" ] || base=$(git merge-base HEAD "$(git -C "$m" rev-parse HEAD 2>/dev/null)" 2>/dev/null) || base=""
  for d in process/specs/active/*/; do
    [ -d "$d" ] || continue
    d=${d%/}
    if [ "${d##*/}" != "$me" ]; then # 分支名和它相同的工作区总是它的主人，别的工作区再看下面两条
      w=$(branch_wt "${d##*/}") && [ -d "$w/$d" ] && continue # 已经挪到同名分支的工作区去做了
      [ -z "$base" ] || ! git cat-file -e "$base:$d" 2>/dev/null || continue # 和主工作区的分叉点里就有：从主线带过来的副本
    fi
    printf '%s\n' "$d"
  done
}
