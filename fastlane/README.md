fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios test_dev

```sh
[bundle exec] fastlane ios test_dev
```

Run app unit tests (development scheme)

### ios cd_dry_run_dev

```sh
[bundle exec] fastlane ios cd_dry_run_dev
```

Dry-run CD for Development (unsigned build + unsigned archive)

### ios cd_dry_run_qa_release

```sh
[bundle exec] fastlane ios cd_dry_run_qa_release
```

Dry-run CD for QA Release (unsigned build + unsigned archive)

### ios cd_dry_run_uat

```sh
[bundle exec] fastlane ios cd_dry_run_uat
```

Dry-run CD for UAT (unsigned build + unsigned archive)

### ios cd_dry_run_prod

```sh
[bundle exec] fastlane ios cd_dry_run_prod
```

Dry-run CD for Production (unsigned build + unsigned archive)

### ios cd_dry_run_all

```sh
[bundle exec] fastlane ios cd_dry_run_all
```

Run all dry-run CD lanes in sequence

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
