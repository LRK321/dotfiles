#!/usr/bin/env bash

input=$(cat)

cwd=$(echo "$input" | jq -r '.cwd // empty')
model=$(echo "$input" | jq -r 'if (.model | type) == "object" then .model.display_name // empty else .model // empty end')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')

# Git branch (skip optional locks)
git_branch=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  git_branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
fi

# Build the status line using ANSI colors (matching PS1)
# Green: user@host  Blue: cwd  Red: git branch
user_host="\033[32m$(whoami)@$(hostname -s)\033[00m"
dir="\033[34m${cwd:-$(pwd)}\033[00m"

if [ -n "$git_branch" ]; then
  branch_part="\033[31m ($git_branch)\033[00m"
else
  branch_part=""
fi

# Context usage
context_part=""
if [ -n "$used" ]; then
  context_part=" | ctx: ${used}%"
fi

# Model part
model_part=""
if [ -n "$model" ]; then
  model_part=" | ${model}"
fi

# Cost part (rightmost)
cost_part=""
if [ -n "$cost" ]; then
  cost_part=$(printf ' | \033[90m$%.2f\033[00m' "$cost")
fi

printf '%b' "${user_host}:${dir}${branch_part}${context_part}${model_part}${cost_part}"
