///|
fn test_env(entries : Array[(String, String)]) -> Map[String, String] {
  Map(entries)
}

///|
fn expect_info(value : @ci.Info?) -> @ci.Info raise {
  match value {
    Some(info) => info
    None => fail("expected CI provider to be detected")
  }
}

///|
fn expect_some(value : String?) -> String raise {
  match value {
    Some(text) => text
    None => fail("expected Some(String)")
  }
}

///|
fn expect_some_bool(value : Bool?) -> Bool raise {
  match value {
    Some(flag) => flag
    None => fail("expected Some(Bool)")
  }
}

///|
async test "public api symbols are exported" {
  let env = test_env([("GITLAB_CI", "true")])
  ignore(@ci.detect_from_env(env))
  ignore(@ci.env_ci_from(env))
  ignore(@ci.env_ci())
  ignore(@ci.is_ci())
  ignore(@ci.service())
  ignore(@ci.name())
}

///|
test "detects gitlab variables" {
  let info = expect_info(
    @ci.detect_from_env(
      test_env([
        ("GITLAB_CI", "true"),
        ("CI_COMMIT_SHA", "abc123"),
        ("CI_COMMIT_REF_NAME", "main"),
        ("CI_PIPELINE_ID", "42"),
        ("CI_PROJECT_URL", "https://gitlab.com/justjavac/ci"),
        ("CI_JOB_ID", "99"),
        ("CI_PROJECT_PATH", "justjavac/ci"),
        ("CI_PROJECT_DIR", "/builds/justjavac/ci"),
      ]),
    ),
  )
  inspect(info.service, content="gitlab")
  inspect(info.name, content="GitLab CI/CD")
  inspect(info.is_ci, content="true")
  inspect(expect_some(info.commit), content="abc123")
  inspect(expect_some(info.branch), content="main")
  inspect(
    expect_some(info.build_url),
    content="https://gitlab.com/justjavac/ci/pipelines/42",
  )
  inspect(
    expect_some(info.job_url),
    content="https://gitlab.com/justjavac/ci/-/jobs/99",
  )
}

///|
test "extracts pull request numbers from urls" {
  let circle = expect_info(
    @ci.detect_from_env(
      test_env([
        ("CIRCLECI", "true"),
        ("CIRCLE_PULL_REQUEST", "https://github.com/justjavac/ci/pull/123"),
        ("CIRCLE_BRANCH", "feature"),
      ]),
    ),
  )
  inspect(expect_some(circle.pr), content="123")
  inspect(expect_some_bool(circle.is_pr), content="true")
  inspect(expect_some(circle.pr_branch), content="feature")

  let buddy = expect_info(
    @ci.detect_from_env(
      test_env([
        ("BUDDY_WORKSPACE_ID", "workspace"),
        ("BUDDY_EXECUTION_PULL_REQUEST_ID", "pull/987"),
        ("BUDDY_EXECUTION_BRANCH", "feature"),
      ]),
    ),
  )
  inspect(expect_some(buddy.pr), content="987")
  assert_true(buddy.branch is None)
}

///|
test "detects supported provider identifiers" {
  let cases : Array[(Map[String, String], String)] = [
    (test_env([("APPVEYOR", "true")]), "appveyor"),
    (test_env([("bamboo_agentId", "agent")]), "bamboo"),
    (test_env([("BITBUCKET_BUILD_NUMBER", "1")]), "bitbucket"),
    (test_env([("BITRISE_IO", "true")]), "bitrise"),
    (test_env([("BUDDY_WORKSPACE_ID", "workspace")]), "buddy"),
    (test_env([("BUILDKITE", "true")]), "buildkite"),
    (test_env([("CIRCLECI", "true")]), "circleci"),
    (test_env([("CIRRUS_CI", "true")]), "cirrus"),
    (test_env([("CODEBUILD_BUILD_ID", "build")]), "codebuild"),
    (test_env([("CF_BUILD_ID", "build")]), "codefresh"),
    (test_env([("CI_NAME", "codeship")]), "codeship"),
    (test_env([("DRONE", "true")]), "drone"),
    (test_env([("GITHUB_ACTION", "test")]), "github"),
    (test_env([("GITLAB_CI", "true")]), "gitlab"),
    (test_env([("JENKINS_URL", "https://jenkins.example")]), "jenkins"),
    (test_env([("SAILCI", "true")]), "sail"),
    (test_env([("SEMAPHORE", "true")]), "semaphore"),
    (test_env([("SHIPPABLE", "true")]), "shippable"),
    (test_env([("TRAVIS", "true")]), "travis"),
    (test_env([("BUILD_BUILDURI", "vsts://build")]), "vsts"),
    (test_env([("WERCKER_MAIN_PIPELINE_STARTED", "1")]), "wercker"),
  ]
  for case in cases {
    let (env, service) = case
    let info = expect_info(@ci.detect_from_env(env))
    inspect(info.service, content=service)
    inspect(info.is_ci, content="true")
  }
}

///|
async test "reads github pull request event metadata" {
  let path = "_build/ci_github_event.json"
  let event_json = "{\"pull_request\":{\"number\":17,\"base\":{\"ref\":\"main\"}}}"
  if !@fs.exists("_build") {
    @fs.mkdir("_build", recursive=true)
  }
  @fs.write_file(path, event_json, create_mode=CreateOrTruncate)
  let info = @ci.env_ci_from(
    test_env([
      ("GITHUB_ACTION", "test"),
      ("GITHUB_EVENT_NAME", "pull_request"),
      ("GITHUB_REF", "refs/heads/feature"),
      ("GITHUB_SHA", "abc123"),
      ("GITHUB_REPOSITORY", "justjavac/ci"),
      ("GITHUB_WORKSPACE", "/work/ci"),
      ("GITHUB_EVENT_PATH", path),
    ]),
  )
  inspect(info.service, content="github")
  inspect(expect_some_bool(info.is_pr), content="true")
  inspect(expect_some(info.branch), content="main")
  inspect(expect_some(info.pr_branch), content="feature")
  inspect(expect_some(info.pr), content="17")
}

///|
async test "falls back to unknown service outside known providers" {
  let info = @ci.env_ci_from(test_env([]), cwd="_build/no-such-ci-repo")
  inspect(info.name, content="unknown")
  inspect(info.service, content="unknown")
  inspect(info.is_ci, content="false")
}
