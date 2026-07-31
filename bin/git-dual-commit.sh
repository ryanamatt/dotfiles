
# Commits to Laptop and PC branches

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
git checkout "$current_branch"
