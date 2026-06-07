# justjavac/ci

[![CI](https://github.com/justjavac/moonbit-ci/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/justjavac/moonbit-ci/actions/workflows/ci.yml)
[![coverage](https://img.shields.io/codecov/c/github/justjavac/moonbit-ci/main?label=coverage)](https://codecov.io/gh/justjavac/moonbit-ci)
[![linux](https://img.shields.io/codecov/c/github/justjavac/moonbit-ci/main?flag=linux&label=linux)](https://codecov.io/gh/justjavac/moonbit-ci)
[![macos](https://img.shields.io/codecov/c/github/justjavac/moonbit-ci/main?flag=macos&label=macos)](https://codecov.io/gh/justjavac/moonbit-ci)
[![windows](https://img.shields.io/codecov/c/github/justjavac/moonbit-ci/main?flag=windows&label=windows)](https://codecov.io/gh/justjavac/moonbit-ci)

Native-only CI environment detection for MoonBit.

```mbt check
///|
async test "detect current ci environment" {
  let info = @ci.env_ci()
  ignore(info.is_ci)
  ignore(info.service)
  ignore(info.branch)
}
```
