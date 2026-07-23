# Branching Strategy

Daira uses **GitHub Flow** -- a simplified, trunk-based workflow. It's the industry-standard
choice for small/early-stage teams shipping continuously, as opposed to GitFlow's heavier
release-branch model, which mainly earns its overhead on products with scheduled multi-version
releases. We don't have that yet, so keep it simple.
___

## Branches

- **`main`** -- always deployable. No direct commits.
- **`feature/<short-description>`** -- one branch per task/feature, cut from `main`.
  e.g. `feature/repo-scaffold`, `feature/fraud-detection-flask-app`
- **`fix/<short-description>`** -- for bug fixes.

## Workflow

1. Branch off `main`:
   ```bash
   git checkout main
   git pull
   git checkout -b feature/your-task-name
   ```
2. Commit in small, logical chunks. Reference the task board item in commit messages where useful.
3. Push and open a PR into `main`.
4. Self-review or peer-review before merge -- at minimum, confirm `docker compose up` still
   works and tests pass.
5. Squash-merge into `main`, delete the feature branch.

## Commit message convention
```
<type>: <short summary>

type = feat | fix | refactor | docs | test | chore
```
Example: `feat: add risk-score endpoint schema and stub service`

## Task board convention
Branch names should loosely map to task board items so it's obvious which task a PR closes
(e.g. Task 1 -> `feature/m0-repo-docker-setup`).
