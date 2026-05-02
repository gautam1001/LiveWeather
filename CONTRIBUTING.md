# Contributing to LiveWeather

## Architecture Rules
- The project follows **CLEAN architecture** with **modularization via Swift Package Manager (SPM)**.
- Core shared layers live in packages such as `Data`, `Domain`, and `Presentation`.
- Feature behavior is implemented via feature packages (API/Impl/Test style where applicable).
- Keep boundaries strict:
  - UI/App composition should not bypass feature APIs.
  - Domain should not depend on Data/Presentation.
  - Data should implement Domain contracts, not the other way around.

## Required Tests
- Run app-level tests:
  - `xcodebuild test -project LiveWeather.xcodeproj -scheme LiveWeather -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:LiveWeatherTests`
- Run package tests:
  - `swift test --package-path Packages/Domain`
  - `swift test --package-path Packages/Data`
  - `swift test --package-path Packages/Presentation`
  - Run feature package tests when changing feature modules.

## Code Coverage
- Target high unit-test coverage for changed modules (team target: around **90%** when practical).
- Ensure Sonar/CI quality gate for coverage on new code passes (current gate may be configured separately in CI/Sonar settings).

## Formatting & Linting (Mandatory Before Commit)
- Run formatter:
  - `swiftformat .`
- Run linter:
  - `swiftlint lint --strict`
- If either fails, fix all issues before pushing.

## CI/CD Expectations
- CI workflows are maintained under:
  - `.github/workflows/liveweather-ci.yml`
  - `.github/workflows/liveweather-cd-dry-run.yml`
- PRs are expected to pass:
  - Code Quality (SwiftLint + SwiftFormat + Semgrep)
  - App Unit Tests
  - Package Tests
  - Sonar scan/quality gate (if enabled for that PR flow)
- Do not merge if required checks are failing or skipped unexpectedly.

## Branch & PR Checklist
- Branching:
  - Create from `Development` using prefixes like `feature/`, `bugfix/`, `chore/`.
- Commit hygiene:
  - Keep commits focused and meaningful.
  - Do not commit unrelated generated/local user files.
- Before opening PR:
  - Rebase/merge latest target branch changes.
  - Run format + lint + required tests locally.
  - Confirm no unintended file changes.
- PR flow:
  - Typical flow is `feature/*` -> `Development`, then `Development` -> `main`.
  - Merge only through PR (no direct pushes to protected branches).
  - Use **squash merge** for short-lived topic branches such as `feature/*`, `bugfix/*`, and `chore/*` when merging into `Development`.
  - Use a **regular merge commit** for `Development` -> `main`. Do **not** squash this PR, because squash merges rewrite ancestry and can cause the same conflicts to reappear in later release PRs.
  - After merging `Development` into `main`, sync `main` back into `Development` to keep long-lived branches aligned and reduce repeat conflict resolution.
- Review readiness:
  - Add clear PR description (what, why, impact, testing done).
  - Ensure CI is green and branch protection rules are satisfied.
