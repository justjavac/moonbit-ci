# justjavac/ci

[![CI](https://github.com/justjavac/moonbit-ci/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/justjavac/moonbit-ci/actions/workflows/ci.yml)
[![coverage](https://img.shields.io/codecov/c/github/justjavac/moonbit-ci/main?label=coverage)](https://codecov.io/gh/justjavac/moonbit-ci)
[![linux](https://img.shields.io/codecov/c/github/justjavac/moonbit-ci/main?flag=linux&label=linux)](https://codecov.io/gh/justjavac/moonbit-ci)
[![macos](https://img.shields.io/codecov/c/github/justjavac/moonbit-ci/main?flag=macos&label=macos)](https://codecov.io/gh/justjavac/moonbit-ci)
[![windows](https://img.shields.io/codecov/c/github/justjavac/moonbit-ci/main?flag=windows&label=windows)](https://codecov.io/gh/justjavac/moonbit-ci)

`justjavac/ci` detects metadata exposed by Continuous Integration providers from MoonBit native programs.

This package only supports the native backend because the complete detection path may call local `git` commands through `moonbitlang/async/process`.

## Installation

```bash
moon add justjavac/ci
```

## Usage

```mbt
async fn main {
  let info = @ci.env_ci()

  if info.is_ci {
    println("Building on \{info.name}")
    match info.slug {
      Some(slug) => println("Repository: \{slug}")
      None => ()
    }
    match info.branch {
      Some(branch) => println("Branch: \{branch}")
      None => ()
    }
  } else {
    println("Not running on a known CI service")
  }
}
```

For deterministic tests or tools that already captured an environment map, use `env_ci_from`:

```mbt
async fn inspect_gitlab {
  let env = {
    "GITLAB_CI": "true",
    "CI_COMMIT_SHA": "abc123",
    "CI_COMMIT_REF_NAME": "main",
  }
  let info = @ci.env_ci_from(env)
  println(info.service) // gitlab
}
```

## API

### `env_ci(cwd? : String = ".") -> Info`

Detects the current process CI environment. Known providers are checked first. If none match, the function runs small `git` commands in `cwd` to fill `commit` and `branch` when possible, and sets `is_ci` from the generic `CI` environment variable.

### `env_ci_from(env : Map[String, String], cwd? : String = ".") -> Info`

Detects CI information from an explicit environment map. This is the preferred entry point for tests.

### `detect_from_env(env : Map[String, String]) -> Info?`

Pure provider detection from environment variables only. It does not read event files or run `git`, so unknown environments return `None`.

### `is_ci`, `service`, `name`

Convenience async helpers for the current process.

## Result Fields

`Info` contains:

| Field | Description |
| --- | --- |
| `name` | CI service display name, for example `GitHub Actions` |
| `service` | Stable service identifier, for example `github` |
| `is_ci` | Whether the current environment is CI |
| `branch` | Git branch being built or targeted by a pull request |
| `commit` | Commit SHA that triggered the build |
| `tag` | Git tag that triggered the build |
| `build` | CI build number or id |
| `build_url` | URL for the CI build |
| `job` | CI job number or id |
| `job_url` | URL for the CI job |
| `is_pr` | Whether the build was triggered by a pull request, when the provider exposes it |
| `pr` | Pull request number |
| `pr_branch` | Source branch for a pull request |
| `slug` | Repository slug in `owner/repo` form when available |
| `root` | Checkout directory used by the CI provider |

## Supported CI Providers

The native MoonBit implementation supports the providers covered by the referenced Deno package:

| Service | Identifier |
| --- | --- |
| AppVeyor | `appveyor` |
| Bamboo | `bamboo` |
| Bitbucket Pipelines | `bitbucket` |
| Bitrise | `bitrise` |
| Buddy | `buddy` |
| Buildkite | `buildkite` |
| CircleCI | `circleci` |
| Cirrus CI | `cirrus` |
| AWS CodeBuild | `codebuild` |
| Codefresh | `codefresh` |
| Codeship | `codeship` |
| Drone | `drone` |
| GitHub Actions | `github` |
| GitLab CI/CD | `gitlab` |
| Jenkins | `jenkins` |
| Sail CI | `sail` |
| Semaphore | `semaphore` |
| Shippable | `shippable` |
| Travis CI | `travis` |
| Visual Studio Team Services | `vsts` |
| Wercker | `wercker` |

If no provider is detected, `service` and `name` are `unknown`. `commit` and `branch` are best-effort values from local git.

## Development

```bash
moon check --target native
moon test --target native
moon test --target native --enable-coverage
moon coverage analyze -p justjavac/ci -- -f summary
```

## License

MIT. See [LICENSE](LICENSE).
