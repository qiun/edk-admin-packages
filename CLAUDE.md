# EDK Admin Packages - Claude Code Instructions

## Git

- Two remotes: `origin` (GitHub) and `gitlab` (GitLab)
- After every commit, always push to both remotes:
  ```
  git push origin main && git push gitlab main:master
  ```
- GitLab uses `master` branch (mapped from local `main`)
