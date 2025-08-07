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

# color definitions
COLOR_NC='\033[0m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m'
COLOR_MAGENTA='\033[0;35m'
COLOR_CYAN='\033[0;36m'
COLOR_BOLD='\033[1m'

# emoji and symbol definitions
EMOJI_BRANCH=" 🌿 "
EMOJI_TOTAL_BRANCHES="🌳"
EMOJI_DEVELOPER="👷"
EMOJI_AHEAD=" ⬆️ "
EMOJI_BEHIND=" ⬇️ "
EMOJI_CURRENT="➜"

# --- auxiliary functions ---

# --- script body ---

# check if in a Git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo -e "${COLOR_RED}error: current directory is not a Git repository.${COLOR_NC}" >&2
    exit 1
fi

# 1. summary
branches=$(git branch --format="%(refname:short)")
num_branches=0
all_developers=()

while IFS= read -r branch; do
    num_branches=$((num_branches + 1))
    # get developers of each branch, and add to total developers list
    branch_developers=$(git log "$branch" --format="%an" | sort -u)
    while IFS= read -r dev; do
        all_developers+=("$dev")
    done <<< "$branch_developers"
done <<< "$branches"

# calculate unique developers
unique_developers=$(printf "%s\n" "${all_developers[@]}" | sort -u | wc -l)

echo -e "${COLOR_BOLD}Branch Summary:${COLOR_NC}"
echo -e "  ${EMOJI_TOTAL_BRANCHES} Total branches: ${COLOR_CYAN}${num_branches}${COLOR_NC}"
echo -e "  ${EMOJI_DEVELOPER} Total unique developers: ${COLOR_CYAN}${unique_developers}${COLOR_NC}"
echo ""

# 2. details
echo -e "${COLOR_BOLD}Branch Details:${COLOR_NC}"

current_branch=$(git branch --show-current)

while IFS= read -r branch; do
    local_branch_name=$(echo "$branch" | sed "s/^[[:space:]*]*//") # remove leading spaces and '*'

    # mark current branch
    prefix=""
    if [ "$local_branch_name" = "$current_branch" ]; then
        prefix="${COLOR_YELLOW}${EMOJI_CURRENT}${COLOR_NC} "
    else
        prefix="  "
    fi

    echo -e "${prefix}${COLOR_CYAN}${local_branch_name}${COLOR_NC}"

    # commit counts of ahead/behind main branch
    main_branch="main" # assume main branch is main
    if git rev-parse --verify "$main_branch" >/dev/null 2>&1; then
        counts=$(git rev-list --left-right --count "${local_branch_name}...${main_branch}" 2>/dev/null)
        if [ -n "$counts" ]; then
            ahead=$(echo "$counts" | awk '{print $1}')
            behind=$(echo "$counts" | awk '{print $2}')
            
            branch_status=""
            if [ "$ahead" -gt 0 ]; then
                branch_status+="${EMOJI_AHEAD}${ahead} "
            fi
            if [ "$behind" -gt 0 ]; then
                branch_status+="${EMOJI_BEHIND}${behind} "
            fi
            
            if [ -n "$branch_status" ]; then
                echo -e "   ${branch_status}vs ${main_branch}"
            fi
        fi
    fi

    # developers of the branch
    branch_developers_raw=$(git log "$local_branch_name" --format="%an" | sort -u)
    branch_dev_count=$(echo "$branch_developers_raw" | wc -l)

    if [ "$branch_dev_count" -gt 0 ]; then
        first_two_devs=$(echo "$branch_developers_raw" | head -n 2 | tr '\n' ',' | sed 's/,$//')
        
        if [ "$branch_dev_count" -gt 2 ]; then
            other_devs=$((branch_dev_count - 2))
            echo -e "    ${EMOJI_DEVELOPER} Developers: ${COLOR_GREEN}${first_two_devs}${COLOR_NC} and ${COLOR_GREEN}${other_devs} others${COLOR_NC}"
        else
            echo -e "    ${EMOJI_DEVELOPER} Developers: ${COLOR_GREEN}${first_two_devs}${COLOR_NC}"
        fi
    fi
    echo "" # each branch gets a new line for better readability

done <<< "$(git branch --format="%(refname:short)")"
