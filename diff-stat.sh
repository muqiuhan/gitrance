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
COLOR_CYAN='\033[0;36m'
COLOR_BOLD='\033[1m'

# summary analysis graph configuration
BAR_WIDTH=40
GREEN_BLOCK="∎"
RED_BLOCK="∎"
EMOJI_SUMMARY=" 📊 "

# file level visualization configuration
CIRCLE="●"
MAX_CIRCLES=10 # maximum number of circles to display for a single item (add/delete)

# --- auxiliary functions ---

function scale_to_circles() {
    local lines=$1
    if ! [[ "$lines" =~ ^[0-9]+$ ]] || [ "$lines" -le 0 ]; then
        echo ""
        return
    fi
    local num_circles
    num_circles=$(awk -v l="$lines" 'BEGIN{c=int(log(l)/log(2))+1; print c}')
    if [ "$num_circles" -gt "$MAX_CIRCLES" ]; then
        num_circles=$MAX_CIRCLES
    fi
    local output=""
    for ((i=0; i<num_circles; i++)); do
        output+="$CIRCLE"
    done
    echo "$output"
}

# --- script body ---

if [ $# -eq 0 ]; then
    set -- --
fi

diff_numstat_output=$(git diff --numstat "$@")
if [ $? -ne 0 ]; then
    exit 1
fi

summary_stats=$(echo "$diff_numstat_output" | awk '{add+=$1; del+=$2} END {print add, del}')
total_added=$(echo "$summary_stats" | awk '{print $1}')
total_deleted=$(echo "$summary_stats" | awk '{print $2}')

if [[ -z "$total_added" && -z "$total_deleted" ]]; then
    echo "No changes."
    exit 0
fi

echo -e "${COLOR_BOLD}Diff summary for: git diff $@${COLOR_NC}"

if [[ "$total_added" -gt 0 || "$total_deleted" -gt 0 ]]; then
    total_change=$((total_added + total_deleted))
    bar=""
    if [ "$total_change" -gt 0 ]; then
        green_len=$((total_added * BAR_WIDTH / total_change))
        red_len=$((BAR_WIDTH - green_len))
        green_bar=""
        for ((i=0; i<green_len; i++)); do green_bar+="${GREEN_BLOCK}"; done
        red_bar=""
        for ((i=0; i<red_len; i++)); do red_bar+="${RED_BLOCK}"; done
        bar="${COLOR_GREEN}${green_bar}${COLOR_NC}${COLOR_RED}${red_bar}${COLOR_NC}"
    fi
    echo -e "${EMOJI_SUMMARY} Total: ${COLOR_GREEN}+${total_added}${COLOR_NC}, ${COLOR_RED}-${total_deleted}${COLOR_NC} ${bar}"
fi
echo ""

echo -e "${COLOR_BOLD}File changes:${COLOR_NC}"

while IFS=$'\t' read -r added deleted path; do
    if [ -z "$path" ]; then continue; fi
    
    path=$(printf "%b" "$path")

    green_circles=$(scale_to_circles "$added")
    red_circles=$(scale_to_circles "$deleted")
    
    # --- ENHANCEMENT: build a string of statistics containing circles and numbers ---
    inner_stat=""
    circles_part="${COLOR_GREEN}${green_circles}${COLOR_NC}${COLOR_RED}${red_circles}${COLOR_NC}"
    
    numeric_parts=()
    if [[ "$added" =~ ^[0-9]+$ ]] && [ "$added" -gt 0 ]; then
        numeric_parts+=("${COLOR_GREEN}+${added}${COLOR_NC}")
    fi
    if [[ "$deleted" =~ ^[0-9]+$ ]] && [ "$deleted" -gt 0 ]; then
        numeric_parts+=("${COLOR_RED}-${deleted}${COLOR_NC}")
    fi

    numeric_part=""
    if [ ${#numeric_parts[@]} -gt 0 ]; then
        numeric_part=$(printf ", %s" "${numeric_parts[@]}")
        numeric_part=${numeric_part:2}
    fi
    
    inner_stat="$circles_part"
    if [ -n "$inner_stat" ] && [ -n "$numeric_part" ]; then
        inner_stat+="  " # if both exist, add a space
    fi
    inner_stat+="$numeric_part"

    stat_str="[${inner_stat}]"
    # --- END ENHANCEMENT --- #
    
    if [[ "$path" == *" => "* ]]; then
        formatted_path=$(echo "$path" | sed -e 's/{//g' -e 's/}//g' -e "s/ => / ${COLOR_BOLD}→${COLOR_NC} /")
    else
        formatted_path="$path"
    fi
    
    echo -e "  ${COLOR_CYAN}${formatted_path}${COLOR_NC}  ${stat_str}"

done <<< "$diff_numstat_output"
