#!/bin/bash
# staged-diff-summary.sh - 显示git仓库暂存区的变化信息
# 作者: Zion Pu

# 默认启用彩色输出
USE_COLOR=true

# 彩色输出函数 - 初始化为空值，稍后会设置
COLOR_RED=""
COLOR_GREEN=""
COLOR_YELLOW=""
COLOR_BLUE=""
COLOR_PURPLE=""
COLOR_CYAN=""
COLOR_RESET=""

# 设置颜色变量
set_colors() {
  if [ "$USE_COLOR" = true ]; then
    COLOR_RED='\033[0;31m'
    COLOR_GREEN='\033[0;32m'
    COLOR_YELLOW='\033[0;33m'
    COLOR_BLUE='\033[0;34m'
    COLOR_PURPLE='\033[0;35m'
    COLOR_CYAN='\033[0;36m'
    COLOR_RESET='\033[0m'
  else
    COLOR_RED=""
    COLOR_GREEN=""
    COLOR_YELLOW=""
    COLOR_BLUE=""
    COLOR_PURPLE=""
    COLOR_CYAN=""
    COLOR_RESET=""
  fi
}

# 用户可配置参数
MAX_DIFF_LINES=100 # 单个文件最大显示的diff行数
BLOCK_SIZE=25      # 分块大小（行）

# 打印带颜色的标题
print_title() {
  local title="$1"
  local color="$2"

  echo -e "\n${color}=== ${title} ===${COLOR_RESET}"
  # echo -e "${color}$(printf '%0.s=' {1..50})${COLOR_RESET}\n"
}

# 检查是否在git仓库中
check_git_repo() {
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo -e "${COLOR_RED}错误：当前目录不是git仓库${COLOR_RESET}"
    exit 1
  fi
}

# 显示git status信息
show_git_status() {
  print_title "Git 仓库状态概览" "${COLOR_BLUE}"

  local status_output=$(git status --porcelain)
  if [ -z "$status_output" ]; then
    echo -e "${COLOR_GREEN}工作区干净，没有需要提交的更改${COLOR_RESET}"
    return
  fi

  # 统计变化数量
  local added=$(echo "$status_output" | grep -c "^A")
  local modified=$(echo "$status_output" | grep -c "^M")
  local deleted=$(echo "$status_output" | grep -c "^D")
  local renamed=$(echo "$status_output" | grep -c "^R")
  local untracked=$(echo "$status_output" | grep -c "^??")
  local staged=$(echo "$status_output" | grep -c "^[AMRD]")
  local not_staged=$(echo "$status_output" | grep -c "^.[AMRD]")

  echo -e "${COLOR_CYAN}文件变化统计:${COLOR_RESET}"
  echo -e "  暂存的更改: ${COLOR_GREEN}$staged${COLOR_RESET}"
  echo -e "  未暂存的更改: ${COLOR_YELLOW}$not_staged${COLOR_RESET}"
  echo -e "  未跟踪的文件: ${COLOR_RED}$untracked${COLOR_RESET}"
  echo -e ""
  echo -e "${COLOR_CYAN}变化类型:${COLOR_RESET}"
  [ $added -gt 0 ] && echo -e "  新增: ${COLOR_GREEN}$added${COLOR_RESET}"
  [ $modified -gt 0 ] && echo -e "  修改: ${COLOR_YELLOW}$modified${COLOR_RESET}"
  [ $deleted -gt 0 ] && echo -e "  删除: ${COLOR_RED}$deleted${COLOR_RESET}"
  [ $renamed -gt 0 ] && echo -e "  重命名: ${COLOR_PURPLE}$renamed${COLOR_RESET}"

  echo -e "\n${COLOR_CYAN}详细状态:${COLOR_RESET}"
  git status -s | sed 's/^/  /'
}

# 显示暂存区文件的统计信息
show_staged_stat() {
  print_title "暂存区文件变化统计" "${COLOR_GREEN}"

  local diff_stat=$(git diff --stat --staged)
  if [ -z "$diff_stat" ]; then
    echo -e "${COLOR_YELLOW}暂存区为空，没有要提交的更改${COLOR_RESET}"
    return
  fi

  echo -e "$diff_stat"
}

# 显示暂存区文件的详细更改，并实现分块显示
show_staged_diff() {
  print_title "暂存区文件详细变化" "${COLOR_PURPLE}"

  # 检查暂存区是否为空
  if ! git diff --cached --quiet; then
    # 使用git diff --name-only --staged -z输出以null字符分隔的文件名列表
    git diff --name-only --staged -z | while IFS= read -d $'\0' file; do
      echo -e "\n${COLOR_CYAN}文件: ${COLOR_YELLOW}$file${COLOR_RESET}"
      echo -e "${COLOR_CYAN}$(printf '%0.s-' {1..80})${COLOR_RESET}"

      # 获取文件的diff
      local file_diff=$(git diff --staged -- "$file")
      local total_lines=$(echo "$file_diff" | wc -l)

      # 如果diff行数超过最大限制，则分块显示
      if [ $total_lines -gt $MAX_DIFF_LINES ]; then
        echo -e "${COLOR_YELLOW}文件变化过大，共 $total_lines 行。显示分块概览...${COLOR_RESET}"

        # 计算需要显示的块数
        local blocks=$((MAX_DIFF_LINES / BLOCK_SIZE))
        local lines_per_block=$((total_lines / blocks))

        # 显示每个分块
        for ((i = 0; i < blocks; i++)); do
          local start=$((i * lines_per_block + 1))
          local end=$((start + BLOCK_SIZE - 1))
          if [ $i -eq $((blocks - 1)) ]; then
            # 最后一个块显示到 BLOCK_SIZE 行
            end=$((start + BLOCK_SIZE - 1))
          fi

          echo -e "\n${COLOR_YELLOW}区块 $((i + 1))/$blocks (第 $start 到 $end 行)${COLOR_RESET}"
          echo "$file_diff" | sed -n "${start},${end}p"

          if [ $i -lt $((blocks - 1)) ]; then
            echo -e "\n${COLOR_YELLOW}... 中间省略 ... ${COLOR_RESET}"
          fi
        done
      else
        # 如果行数不多，直接显示完整diff
        echo "$file_diff"
      fi
    done
  else
    echo -e "${COLOR_YELLOW}暂存区为空，没有要提交的更改${COLOR_RESET}"
  fi
}

# 显示帮助信息
show_help() {
  echo "用法: $(basename $0) [选项]"
  echo "显示git仓库暂存区的变化信息，结构化清晰地展示。"
  echo ""
  echo "选项:"
  echo "  -n, --no-color    禁用彩色输出"
  echo "  -h, --help        显示此帮助信息"
  echo ""
  echo "示例:"
  echo "  $(basename $0)            # 使用默认设置显示变化"
  echo "  $(basename $0) --no-color # 禁用彩色输出"
  echo ""
  exit 0
}

# 主函数
main() {
  # 解析命令行参数
  while [[ "$#" -gt 0 ]]; do
    case $1 in
    -n | --no-color) USE_COLOR=false ;;
    -h | --help) show_help ;;
    *)
      echo "未知选项: $1" >&2
      show_help
      ;;
    esac
    shift
  done

  # 设置颜色
  set_colors

  check_git_repo

  # echo -e "${COLOR_CYAN}$(printf '%0.s#' {1..80})${COLOR_RESET}"
  # echo -e "${COLOR_CYAN}#${COLOR_RESET}                    ${COLOR_GREEN}Git 仓库变化摘要${COLOR_RESET}                     ${COLOR_CYAN}#${COLOR_RESET}"
  # echo -e "${COLOR_CYAN}$(printf '%0.s#' {1..80})${COLOR_RESET}\n"

  show_git_status
  show_staged_stat
  show_staged_diff

  # echo -e "\n${COLOR_BLUE}$(printf '%0.s=' {1..80})${COLOR_RESET}"
  # echo -e "${COLOR_GREEN}摘要生成完成，感谢使用！${COLOR_RESET}"
}

# 执行主函数
main "$@"
