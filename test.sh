#!/usr/bin/env bash

# this script will create a git test repo, which contains various scenarios for testing gitrance scripts.

set -e # exit on error
trap 'echo "script failed at line $LINENO, please check." >&2' ERR

# --- config ---
REPO_NAME="gitrance_test_repo"
MAIN_BRANCH="main"
DEV_BRANCH="dev/feature-A"
OTHER_DEV_BRANCH="dev/feature-B"
RELEASE_BRANCH="release/v1.0"
AUTHOR_1="Alice <alice@example.com>"
AUTHOR_2="Bob <bob@example.com>"
AUTHOR_3="Charlie <charlie@example.com>"

# --- helper functions ---

# helper function to create a commit
create_commit() {
    local message="$1"
    local author="$2"
    shift 2
    git -c user.name="${author%%<*}" -c user.email="${author##*<}" commit -m "$message" "$@"
}

# simulate waiting time, ensure different commit timestamps
wait_a_bit() {
    sleep 0.1
}

echo "--- creating test repo: ${REPO_NAME} ---"

# 1. initialize repo and create initial commit
rm -rf "$REPO_NAME"
mkdir "$REPO_NAME"
cd "$REPO_NAME"

git init -b "$MAIN_BRANCH"
git config user.name "Gitrance Test User"
git config user.email "test@gitrance.com"

echo "Initial content." > README.md
git add README.md
create_commit "Initial commit" "$AUTHOR_1"
wait_a_bit

# 2. prepare scenarios for branch.sh and log.sh

echo "--- prepare scenarios for branch.sh and log.sh ---"

# create a dev branch
git checkout -b "$DEV_BRANCH"
echo "Feature A content." > feature-A.txt
git add feature-A.txt
create_commit "feat: Add feature A" "$AUTHOR_1"
wait_a_bit
echo "More feature A content." >> feature-A.txt
create_commit "refactor: Improve feature A" "$AUTHOR_1"
wait_a_bit

# back to main branch, and create another dev branch
git checkout "$MAIN_BRANCH"
echo "More content on main." >> README.md
create_commit "docs: Update README on main" "$AUTHOR_2" # simulate different authors
wait_a_bit

git checkout -b "$OTHER_DEV_BRANCH"
echo "Feature B content." > feature-B.txt
git add feature-B.txt
create_commit "feat: Add feature B" "$AUTHOR_2"
wait_a_bit
echo "More feature B content." >> feature-B.txt
create_commit "fix: Fix bug in feature B" "$AUTHOR_3" # simulate different authors
wait_a_bit

# make DEV_BRANCH ahead of main
git checkout "$DEV_BRANCH"
echo "Even more feature A content." >> feature-A.txt
create_commit "chore: Final adjustments for feature A" "$AUTHOR_1"
wait_a_bit

# merge DEV_BRANCH into main, create merge commit
git checkout "$MAIN_BRANCH"
git merge "$DEV_BRANCH" -m "merge: Merge feature A into main"
wait_a_bit

# create a release branch, and make it behind main (main has new commits)
git checkout -b "$RELEASE_BRANCH"
# this branch is currently the same as main, but main will have new commits after it, making it behind
wait_a_bit

# main continue to move forward, making release branch behind
git checkout "$MAIN_BRANCH"
echo "New feature on main after release branch creation." > new-feature.txt
git add new-feature.txt
create_commit "feat: Add new feature post-release-branch" "$AUTHOR_1"
wait_a_bit

# create tags for log.sh
git tag -a v1.0.0 -m "Release version 1.0.0" "$RELEASE_BRANCH"
git tag v1.0.0-rc1 # lightweight tag

# create a detached HEAD state
git checkout HEAD~1 # detach HEAD to the second last commit
echo "Detached HEAD state." > detached.txt
git add detached.txt
create_commit "debug: Detached HEAD commit" "$AUTHOR_3"
wait_a_bit
git checkout "$MAIN_BRANCH" # switch back to main branch

# 3. prepare scenarios for status.sh and diff-stat.sh

echo "--- prepare scenarios for status.sh and diff-stat.sh ---"

# staged changes
echo "Staged new file." > staged_new.txt
git add staged_new.txt
echo "This is a modified file." > staged_modified.txt
create_commit "temp: Add staged_modified for later use" "$AUTHOR_1" staged_modified.txt # 先提交以便修改
wait_a_bit
echo "This file has been modified in staging." >> staged_modified.txt
git add staged_modified.txt

echo "This file will be deleted." > staged_deleted.txt
create_commit "temp: Add staged_deleted for later use" "$AUTHOR_1" staged_deleted.txt # 先提交以便删除
wait_a_bit
git rm staged_deleted.txt
wait_a_bit

# rename file
echo "Original content." > old_name.txt
create_commit "temp: Add old_name for later rename" "$AUTHOR_1" old_name.txt # 先提交以便重命名
wait_a_bit
git mv old_name.txt new_name.txt
wait_a_bit

# unstaged changes
echo "This file exists." > unstaged_modified.txt
create_commit "temp: Add unstaged_modified for later use" "$AUTHOR_1" unstaged_modified.txt # 先提交以便修改
wait_a_bit
echo "This file has been modified in working directory." >> unstaged_modified.txt
# do not git add

echo "This file will be deleted from working directory." > unstaged_deleted.txt
create_commit "temp: Add unstaged_deleted for later use" "$AUTHOR_1" unstaged_deleted.txt # 先提交以便删除
wait_a_bit
rm unstaged_deleted.txt
# do not git add

# untracked files
echo "This is an untracked file." > untracked_file.txt
mkdir untracked_dir
echo "Untracked file in dir." > untracked_dir/file_in_dir.txt

# conflicts
echo "--- prepare conflicts scenario ---"
git checkout -b conflict_branch
echo "Content from conflict_branch." > conflict_file.txt
git add conflict_file.txt
create_commit "feat: Add conflict file on conflict_branch" "$AUTHOR_1"
wait_a_bit

git checkout "$MAIN_BRANCH"
echo "Content from main branch, different." > conflict_file.txt
git add conflict_file.txt
create_commit "feat: Add conflict file on main" "$AUTHOR_2"
wait_a_bit

# try to merge to create conflict
echo "Attempting to create merge conflict..."
if git merge conflict_branch --no-commit; then
    echo "Conflict did not occur as expected. Please check manually."
else
    echo "Merge conflict created successfully!"
fi

# diff-stat large changes
echo "--- prepare diff-stat.sh large changes scenario ---"
# create a file with large number of lines
echo "Line 1" > large_change.txt
echo "Line 2" >> large_change.txt
echo "Line 3" >> large_change.txt
create_commit "temp: Add large_change.txt" "$AUTHOR_1" large_change.txt # 先提交
wait_a_bit

# make large changes
for i in $(seq 1 50); do echo "Added line $i" >> large_change.txt; done
for i in $(seq 1 10); do sed -i "${i}d" large_change.txt; done # delete some lines

# do not git add, so diff-stat.sh can show unstaged changes
echo "Simulating large changes (unstaged) for diff-stat.sh"

echo ""
echo "--- test repo created! ---"
echo "now you can enter '${REPO_NAME}' directory and run 'git status' or other gitrance commands for testing."
echo "for example:"
echo "cd $REPO_NAME"
echo "chmod +x ../*.sh" # ensure scripts are executable
echo "git config alias.br '!$(pwd)/../branch.sh'"
echo "git config alias.st '!$(pwd)/../status.sh'"
echo "git config alias.dst '!$(pwd)/../diff-stat.sh'"
echo "git config alias.lg '!$(pwd)/../log.sh'"
echo ""
echo "then you can try:"
echo "git br"
echo "git st"
echo "git dst"
echo "git lg"
echo "git lg --all --decorate --oneline" # combine gitrance and git log native parameters
echo ""
echo "run 'git st' and 'git dst' on conflict_file.txt to see conflict status."
echo "run 'git dst' on unstaged_modified.txt and large_change.txt to see unstaged changes."
echo ""