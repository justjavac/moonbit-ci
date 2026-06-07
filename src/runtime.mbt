///|
/// Pull request details read from provider event metadata.
priv struct GithubPrEvent {
  branch : String?
  pr : String?
}

///|
/// Detect CI information from the current process environment.
///
/// If no known provider is detected, this falls back to local git metadata and
/// sets `is_ci` from the generic `CI` environment variable.
pub async fn env_ci(cwd? : String = ".") -> Info {
  env_ci_from(@env.get_env_vars(), cwd~)
}

///|
/// Detect CI information from an explicit environment map.
///
/// This is the deterministic entry point for tests and callers that already
/// captured an environment. Provider-specific environment variables are checked
/// first. If none match, the function runs small `git` commands in `cwd` to
/// fill `commit` and `branch`, matching the fallback behavior of `deno-ci`.
pub async fn env_ci_from(
  env : Map[String, String],
  cwd? : String = ".",
) -> Info {
  if env_has(env, "GITHUB_ACTION") {
    let pr_event = if env_get(env, "GITHUB_EVENT_NAME") == Some("pull_request") {
      read_github_pr_event(env)
    } else {
      None
    }
    return github_info(env, pr_event~)
  }

  if env_has(env, "CODEBUILD_BUILD_ID") {
    let head = git_head(env, cwd)
    let branch = git_branch(env, cwd)
    return { ..codebuild_info(env), commit: head, branch }
  }

  if env_has(env, "JENKINS_URL") {
    return jenkins_info(env, git_head=git_head(env, cwd))
  }

  if env_has(env, "SEMAPHORE") {
    return semaphore_info(env, git_head=git_head(env, cwd))
  }

  match detect_from_env(env) {
    Some(info) => info
    None => git_fallback_info(env, cwd)
  }
}

///|
/// Return whether the current process appears to be running in CI.
pub async fn is_ci(cwd? : String = ".") -> Bool {
  env_ci(cwd~).is_ci
}

///|
/// Return the current CI service identifier, or `unknown` for the git fallback.
pub async fn service(cwd? : String = ".") -> String {
  env_ci(cwd~).service
}

///|
/// Return the current CI service display name, or `unknown` for the git fallback.
pub async fn name(cwd? : String = ".") -> String {
  env_ci(cwd~).name
}

///|
async fn git_fallback_info(env : Map[String, String], cwd : String) -> Info {
  {
    ..base_info("unknown", "unknown", is_ci=env_has(env, "CI")),
    commit: git_head(env, cwd),
    branch: git_branch(env, cwd),
  }
}

///|
async fn git_head(env : Map[String, String], cwd : String) -> String? {
  git_stdout(env, cwd, ["rev-parse", "HEAD"])
}

///|
async fn git_branch(env : Map[String, String], cwd : String) -> String? {
  match git_stdout(env, cwd, ["rev-parse", "--abbrev-ref", "HEAD"]) {
    Some("HEAD") => detached_head_branch(env, cwd)
    other => other
  }
}

///|
async fn detached_head_branch(
  env : Map[String, String],
  cwd : String,
) -> String? {
  match git_stdout(env, cwd, ["show", "-s", "--pretty=%d", "HEAD"]) {
    Some(output) => origin_branch_from_decoration(output)
    None => None
  }
}

///|
async fn git_stdout(
  env : Map[String, String],
  cwd : String,
  args : Array[String],
) -> String? {
  try {
    let (status, stdout, _) = @process.collect_output(
      "git",
      args,
      extra_env=env,
      inherit_env=true,
      cwd~,
    )
    if status == 0 {
      let text = stdout.text().trim().to_owned()
      if text == "" {
        None
      } else {
        Some(text)
      }
    } else {
      None
    }
  } catch {
    _ => None
  }
}

///|
fn origin_branch_from_decoration(output : String) -> String? {
  let normalized = output.trim().to_owned()
  let without_open = match normalized.strip_prefix("(") {
    Some(value) => value.to_owned()
    None => normalized
  }
  let without_close = match without_open.strip_suffix(")") {
    Some(value) => value.to_owned()
    None => without_open
  }
  for part in without_close.split(", ") {
    let text = part.to_owned()
    match text.strip_prefix("origin/") {
      Some(branch) => return Some(branch.to_owned())
      None => ()
    }
  }
  None
}

///|
async fn read_github_pr_event(env : Map[String, String]) -> GithubPrEvent? {
  match env_get(env, "GITHUB_EVENT_PATH") {
    None => None
    Some(path) =>
      parse_github_pr_event(@json.parse(@fs.read_file(path).text())) catch {
        _ => None
      }
  }
}

///|
fn parse_github_pr_event(json : Json) -> GithubPrEvent? {
  match json {
    Object(fields) =>
      match fields.get("pull_request") {
        Some(Object(pr_fields)) => {
          let pr = json_stringish(pr_fields.get("number"))
          let branch = match pr_fields.get("base") {
            Some(Object(base_fields)) =>
              branch_from_ref(json_stringish(base_fields.get("ref")))
            _ => None
          }
          Some({ branch, pr })
        }
        _ => None
      }
    _ => None
  }
}

///|
fn json_stringish(value : Json?) -> String? {
  match value {
    Some(String(text)) => Some(text)
    Some(Number(_, repr=Some(repr))) => Some(repr)
    Some(Number(number, repr=None)) => Some(number.to_string())
    _ => None
  }
}
