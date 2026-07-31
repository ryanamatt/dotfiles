#!/usr/bin/env bash

# Commits to Laptop and PC branches

push=false

# Parse arguments
while getopts ":p" opt; do
    case ${opt} in
        p )
            push=true
            ;;
        \? )
            echo "Invalid option: -$OPTARG" 1>&2
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

msg="$1"

if [ -z "$msg" ]; then
    echo "Error: No commit message provided."
    exit 1
fi

current_branch=$(git symbolic-ref --short HEAD)

git commit -m "$msg"
commit_hash=$(git rev-parse HEAD)

other_branch="laptop"
[ "$current_branch" = "laptop" ] && other_branch="pc"

# Apply to the other branch
git checkout "$other_branch"
git cherry-pick "$commit_hash"
if [ "$push" = true ]; then
    git push origin "$other_branch"
fi
git checkout "$current_branch"
if [ "$push" = true ]; then
    git push origin "$current_branch"
fi
