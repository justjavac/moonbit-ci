name = "justjavac/ci"

version = "0.1.0"

readme = "README.mbt.md"

import {
  "moonbitlang/async@0.19.2",
}

repository = "https://github.com/justjavac/moonbit-ci"

license = "MIT"

keywords = [
  "ci",
  "continuous-integration",
  "github-actions",
  "gitlab-ci",
  "native",
]

description = "Native-only CI environment detection for MoonBit."

warnings = ""

preferred_target = "native"

supported_targets = "+native"

options(
  source: "src",
)
