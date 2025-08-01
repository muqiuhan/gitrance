#!/usr/bin/env bash
# Copyright (c) 2025 Somhairle H. Marisol
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice,
#       this list of conditions and the following disclaimer in the documentation
#       and/or other materials provided with the distribution.
#     * Neither the name of Gitrance nor the names of its contributors
#       may be used to endorse or promote products derived from this software
#       without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# --- configuration (can be customized here) ---

# color definitions (ANSI Escape Codes)
COLOR_NC='\033[0m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_CYAN='\033[0;36m'
COLOR_BOLD='\033[1m'

# emoji definitions
EMOJI_BRANCH=" 🌿 "
EMOJI_AHEAD="⬆️ "
EMOJI_BEHIND="⬇️ "
EMOJI_DIVERGED=" 🔱 "
EMOJI_STAGED=" ✅ "
EMOJI_MODIFIED=" 📝 "
EMOJI_DELETED=" 🗑️ "
EMOJI_RENAMED="➡️ "
EMOJI_UNTRACKED=" ❓ "
EMOJI_CLEAN="✔️"
EMOJI_CONFLICT="⚠️ "
EMOJI_SUMMARY=" 📊 "

# difference statistics bar configuration
BAR_WIDTH=30
GREEN_BLOCK="∎"
RED_BLOCK="∎"

# --- auxiliary functions ---

# get the number of added and deleted lines for a single file
# $1: 'staged' or 'unstaged'
# $2: file path
function get_diff_stats() {
    local type=$1
    local file_path=$2
    local added deleted
    
    if [ "$type" == "staged" ]; then
        # --staged option is used to compare the staging area and HEAD
        read added deleted _ <<< "$(git diff --staged --numstat -- "$file_path")"
    else
        # default comparison between working area and staging area
        read added deleted _ <<< "$(git diff --numstat -- "$file_path")"
    fi
    
    # only output when valid numbers are obtained
    if [[ -n "$added" && -n "$deleted" && "$added" -gt 0 || "$deleted" -gt 0 ]]; then
        echo -e " ${COLOR_BOLD}[${COLOR_GREEN}+${added}${COLOR_NC}, ${COLOR_RED}-${deleted}${COLOR_NC}${COLOR_BOLD}]${COLOR_NC}"
    fi
}

# --- script body ---

# check if in a Git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo -e "${COLOR_RED}error: current directory is not a Git repository.${COLOR_NC}"
    exit 1
fi

# 1. get branch information
current_branch=$(git branch --show-current)
if [ -z "$current_branch" ]; then
    current_branch=$(git rev-parse --short HEAD)
    branch_info="${COLOR_YELLOW}(HEAD detached at ${current_branch})${COLOR_NC}"
else
    branch_info="${COLOR_CYAN}${current_branch}${COLOR_NC}"
    remote=$(git config "branch.${current_branch}.remote")
    if [ -n "$remote" ]; then
        merge_branch=$(git config "branch.${current_branch}.merge")
        remote_branch="${remote}/$(basename "$merge_branch")"
        counts=$(git rev-list --left-right --count "HEAD...${remote_branch}" 2>/dev/null)
        if [ -n "$counts" ]; then
            ahead=$(echo "$counts" | awk '{print $1}')
            behind=$(echo "$counts" | awk '{print $2}')
            if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
                branch_info+=" [${EMOJI_DIVERGED} Diverged: ${EMOJI_AHEAD}${ahead} ${EMOJI_BEHIND}${behind} | ${remote_branch}]"
            elif [ "$ahead" -gt 0 ]; then
                branch_info+=" [${EMOJI_AHEAD}${ahead} Ahead | ${remote_branch}]"
            elif [ "$behind" -gt 0 ]; then
                branch_info+=" [${EMOJI_BEHIND}${behind} Behind | ${remote_branch}]"
            else
                 branch_info+=" [Up-to-date with ${remote_branch}]"
            fi
        fi
    else
        branch_info+=" [No remote tracking]"
    fi
fi

echo -e "${EMOJI_BRANCH} On branch ${branch_info}"

# 2. calculate and display the total difference statistics of the staging area
staged_stats=$(git diff --staged --numstat | awk '{add+=$1; del+=$2} END {print add, del}')
total_added=$(echo "$staged_stats" | awk '{print $1}')
total_deleted=$(echo "$staged_stats" | awk '{print $2}')

if [[ "$total_added" -gt 0 || "$total_deleted" -gt 0 ]]; then
    total_change=$((total_added + total_deleted))
    green_len=$((total_added * BAR_WIDTH / total_change))
    red_len=$((BAR_WIDTH - green_len))

    bar=""
    for ((i=0; i<green_len; i++)); do bar+="${GREEN_BLOCK}"; done
    bar="${COLOR_GREEN}${bar}${COLOR_NC}"
    
    red_bar=""
    for ((i=0; i<red_len; i++)); do red_bar+="${RED_BLOCK}"; done
    bar+="${COLOR_RED}${red_bar}${COLOR_NC}"

    echo -e "${EMOJI_SUMMARY} Staged changes summary: ${COLOR_GREEN}+${total_added}${COLOR_NC}, ${COLOR_RED}-${total_deleted}${COLOR_NC} ${bar}"
fi

echo "" # empty line

# 3. get file status
status_output=$(git status --porcelain=v1)

if [ -z "$status_output" ]; then
    echo -e "${EMOJI_CLEAN} ${COLOR_GREEN}The working area is clean, no modifications.${COLOR_NC}"
    exit 0
fi

# flag to control the printing of paragraph titles
staged_header_printed=false
unstaged_header_printed=false
untracked_header_printed=false
conflicts_header_printed=false

while IFS= read -r line; do
    status=${line:0:2}
    path=${line:3}
    stats="" # reset

    # determine the output format based on the status code
    case "$status" in
        # --- Staged Changes ---
        A\ )
            if ! $staged_header_printed; then echo -e "${COLOR_BOLD}Staged changes:${COLOR_NC}"; staged_header_printed=true; fi
            stats=$(get_diff_stats "staged" "$path")
            echo -e "   ${EMOJI_STAGED} ${COLOR_GREEN}new file:   ${path}${stats}${COLOR_NC}" ;;
        M\ )
            if ! $staged_header_printed; then echo -e "${COLOR_BOLD}Staged changes:${COLOR_NC}"; staged_header_printed=true; fi
            stats=$(get_diff_stats "staged" "$path")
            echo -e "   ${EMOJI_STAGED} ${COLOR_GREEN}modified:   ${path}${stats}${COLOR_NC}" ;;
        D\ )
            if ! $staged_header_printed; then echo -e "${COLOR_BOLD}Staged changes:${COLOR_NC}"; staged_header_printed=true; fi
            stats=$(get_diff_stats "staged" "$path")
            echo -e "   ${EMOJI_STAGED} ${COLOR_RED}deleted:    ${path}${stats}${COLOR_NC}" ;;
        R\ )
            if ! $staged_header_printed; then echo -e "${COLOR_BOLD}Staged changes:${COLOR_NC}"; staged_header_printed=true; fi
            echo -e "   ${EMOJI_STAGED} ${COLOR_PURPLE}renamed:    ${path}${COLOR_NC}" ;;
        # --- Unstaged Changes ---
        \ M)
            if ! $unstaged_header_printed; then echo -e "\n${COLOR_BOLD}Unstaged changes:${COLOR_NC}"; unstaged_header_printed=true; fi
            stats=$(get_diff_stats "unstaged" "$path")
            echo -e "   ${EMOJI_MODIFIED} ${COLOR_YELLOW}modified:   ${path}${stats}${COLOR_NC}" ;;
        \ D)
            if ! $unstaged_header_printed; then echo -e "\n${COLOR_BOLD}Unstaged changes:${COLOR_NC}"; unstaged_header_printed=true; fi
            echo -e "   ${EMOJI_DELETED} ${COLOR_RED}deleted:    ${path}${COLOR_NC}" ;; # deleted files have no working area difference
        # --- Combined Staged/Unstaged ---
        MM)
            if ! $staged_header_printed; then echo -e "${COLOR_BOLD}Staged changes:${COLOR_NC}"; staged_header_printed=true; fi
            stats_staged=$(get_diff_stats "staged" "$path")
            echo -e "   ${EMOJI_STAGED} ${COLOR_GREEN}modified:   ${path}${stats_staged}${COLOR_NC}"
            if ! $unstaged_header_printed; then echo -e "\n${COLOR_BOLD}Unstaged changes:${COLOR_NC}"; unstaged_header_printed=true; fi
            stats_unstaged=$(get_diff_stats "unstaged" "$path")
            echo -e "   ${EMOJI_MODIFIED} ${COLOR_YELLOW}modified:   ${path}${stats_unstaged}${COLOR_NC}" ;;
        # --- Conflicts ---
        DD|AU|UD|UA|DU|AA|UU)
            if ! $conflicts_header_printed; then echo -e "\n${COLOR_BOLD}Unmerged paths (conflicts):${COLOR_NC}"; conflicts_header_printed=true; fi
            echo -e "   ${EMOJI_CONFLICT} ${COLOR_RED}conflict:     ${path}${COLOR_NC}" ;;
        # --- Untracked Files ---
        \?\?)
            if ! $untracked_header_printed; then echo -e "\n${COLOR_BOLD}Untracked files:${COLOR_NC}"; untracked_header_printed=true; fi
            echo -e "   ${EMOJI_UNTRACKED} ${COLOR_CYAN}${path}${COLOR_NC}" ;;
    esac
done <<< "$status_output"
