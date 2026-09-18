#!/usr/bin/env bash

# Counts the number of commits between consecutive git tags and since the last tag.

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: Not a git repository." >&2
    exit 1
fi

mapfile -t tags < <(git tag --sort=version:refname)

if [ ${#tags[@]} -eq 0 ]; then
    echo "Error: No tags found in this repository." >&2
    exit 1
fi

first_tag="${tags[0]}"
first_count=$(git rev-list --count "${first_tag}")
total_commits=$first_count
echo "${first_tag}: ${first_count}"

for ((i=0; i<${#tags[@]}-1; i++)); do
    prev_tag="${tags[i]}"
    curr_tag="${tags[i+1]}"
    
    count=$(git rev-list --count "${prev_tag}..${curr_tag}")
    total_commits=$(( total_commits + count ))
    
    echo "${curr_tag}: ${count}"
done

last_tag="${tags[-1]}"
since_last_count=$(git rev-list --count "${last_tag}..HEAD")
total_commits=$(( total_commits + since_last_count ))
echo "Since Last Tag: ${since_last_count}"

echo ""
echo "Total Commits: ${total_commits}"
