
# Do a full local backup of a github repository

```git clone --mirror https://github.com/USER/REPO.git```


Source: https://docs.github.com/en/repositories/archiving-a-github-repository/backing-up-a-repository?utm_source=chatgpt.com


# Get all branches locally:

git fetch origin
for b in $(git for-each-ref --format='%(refname:strip=3)' refs/remotes/origin/); do
  [ "$b" = "HEAD" ] || git show-ref -q --verify "refs/heads/$b" || git branch --track "$b" "origin/$b"
done