# Naming Conventions

Shared naming standards for all recipes across Claude Code and Goose.

## Recipe Files

| Context | Convention | Example |
|---------|-----------|---------|
| Recipe file names | `kebab-case` | `code-reviewer.yaml`, `api-designer.md` |
| Recipe identifiers | `kebab-case` | `code-reviewer`, `python-expert` |
| Recipe display names | Title Case | "Code Reviewer", "Python Expert" |
| Subrecipe files | `kebab-case` | `tdd-generic.yaml`, `language-detection.md` |

## Parameters (Goose YAML)

| Context | Convention | Example |
|---------|-----------|---------|
| Parameter keys | `snake_case` | `target_path`, `review_depth` |
| Parameter options | `snake_case` | `quick`, `full_audit`, `report_only` |

## Code Conventions (enforced by recipes)

| Language | Convention | Example |
|----------|-----------|---------|
| Python modules | `snake_case` | `mlflow_config.py` |
| Python classes | `PascalCase` | `ExperimentConfig` |
| Python functions | `snake_case` | `compute_data_hash()` |
| TypeScript files | `kebab-case` | `user-service.ts` |
| Dart files | `snake_case` | `user_repository.dart` |
| Rust modules | `snake_case` | `error_handler.rs` |
| PostgreSQL tables | `plural snake_case` | `users`, `workout_sessions` |
| REST URLs | `kebab-case` | `/api/v1/user-profiles` |
| GraphQL types | `PascalCase` | `UserConnection` |
| CSS tokens | `kebab-case` | `--color-primary` |
| Git branches | `type/kebab-case` | `feature/user-auth`, `fix/null-pointer` |
| Commit types | `lowercase` | `feat`, `fix`, `docs`, `test` |
| Bash variables | `UPPER_SNAKE_CASE` | `SCRIPT_DIR`, `MAX_RETRIES` |
