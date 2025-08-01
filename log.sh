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
COLOR_WHITE_BOLD='\033[1;37m'

# emoji and symbol definitions
EMOJI_HEAD="📍"
EMOJI_REMOTE="☁️ "
EMOJI_TAG="🏷️ "
EMOJI_LOCAL_BRANCH="🌿"
EMOJI_AUTHOR="👤"
EMOJI_DATE="⏰"
SYMBOL_SHA="➜"

# --- auxiliary functions ---

function parse_decorations() {
    local raw_decorations="$1"
    if [ -z "$raw_decorations" ]; then
        echo ""
        return
    fi
    local trimmed_decorations
    trimmed_decorations=$(echo "$raw_decorations" | sed 's/^[ (]*//;s/[ )]*$//')
    IFS=',' read -ra refs <<< "$trimmed_decorations"
    local formatted_output=""
    for ref in "${refs[@]}"; do
        ref=$(echo "$ref" | xargs)
        local formatted_ref=""
        case "$ref" in
            HEAD*)
                # split and format "HEAD -> branch"
                local head_part="${ref%% -> *}"
                local branch_part="${ref#* -> }"
                formatted_ref="${COLOR_GREEN}${EMOJI_HEAD} ${head_part} -> ${branch_part}${COLOR_NC}"
                ;;
            tag:*)
                # remove "tag: " prefix
                ref="${ref#tag: }"
                formatted_ref="${COLOR_MAGENTA}${EMOJI_TAG} ${ref}${COLOR_NC}"
                ;;
            origin/*)
                formatted_ref="${COLOR_RED}${EMOJI_REMOTE}${ref}${COLOR_NC}"
                ;;
            *)
                if [ -n "$ref" ]; then
                    formatted_ref="${COLOR_CYAN}${EMOJI_LOCAL_BRANCH} ${ref}${COLOR_NC}"
                fi
                ;;
        esac
        # add a space before each element
        [ -n "$formatted_ref" ] && formatted_output+=" ${formatted_ref}"
    done
    echo -n "${formatted_output}"
}


# --- script body ---

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo -e "${COLOR_RED}error: current directory is not a Git repository.${COLOR_NC}" >&2
    exit 1
fi

# use Unit Separator (ASCII 31) as field separator, a non-printable character,
# unlikely to appear in commit messages, making it an ideal delimiter.
readonly US=$'\x1f'

# define the output format of git log.
# %h: abbreviated hash | %d: ref name | %s: summary | %an: author | %ar: relative author date
log_format="%h${US}%d${US}%s${US}%an${US}%ar"

# core logic:
# 1. use 'git log --graph' to generate a log with a topological structure.
# 2. use the format we defined '--pretty=format:${log_format}'.
# 3. read the output line by line.
git log --graph --date=relative --pretty=format:"${log_format}" "$@" | while IFS= read -r full_line || [[ -n "$full_line" ]]; do
    
    # FIX: critical correction. check if the current line contains our delimiter '$US'.
    # if not, it means this is a pure graph line, output it and process the next line.
    if [[ "$full_line" != *"$US"* ]]; then
        echo -e "${full_line}"
        continue
    fi

    # FIX: robust parsing logic.
    # for lines containing commit information, the format is: <graph_chars> <commit_data>
    # we split the line at the first '$US' delimiter.
    graph_and_hash_part="${full_line%%${US}*}"
    fields_part="${full_line#*${US}}"

    # separate the last word from 'graph_and_hash_part' as the hash, the rest as the graph.
    # this method works for all cases of `*`, `* `, `|/ `, `* |`.
    sha="${graph_and_hash_part##* }"
    graph_prefix="${graph_and_hash_part% *}"

    # now use '$US' as a delimiter to parse 'fields_part'.
    # note that the first field (hash) has been processed, so we start from decorations.
    IFS="$US" read -r decorations subject author date <<< "$fields_part"

    formatted_decorations=$(parse_decorations "$decorations")

    # FIX: build a single line output, conforming to the expected hierarchical structure design.
    line="${graph_prefix} ${COLOR_YELLOW}${SYMBOL_SHA} ${sha}${COLOR_NC}"
    line+="${formatted_decorations}" # already contains leading space
    line+=" ${COLOR_WHITE_BOLD}${subject}${COLOR_NC}"
    line+=" ${COLOR_CYAN} ${EMOJI_AUTHOR} ${author}${COLOR_NC}"
    line+=" ${COLOR_BLUE} ${EMOJI_DATE} ${date}${COLOR_NC}"
    
    echo -e "${line}"

done
