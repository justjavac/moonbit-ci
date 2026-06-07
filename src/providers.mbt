///|
/// Detect CI information from environment variables only.
///
/// This pure entry point does not run git commands or read provider event
/// files. Use `env_ci_from` when you also want the local git fallback.
pub fn detect_from_env(env : Map[String, String]) -> Info? {
  if env_has(env, "APPVEYOR") {
    Some(appveyor_info(env))
  } else if env_has(env, "bamboo_agentId") {
    Some(bamboo_info(env))
  } else if env_has(env, "BITBUCKET_BUILD_NUMBER") {
    Some(bitbucket_info(env))
  } else if env_has(env, "BITRISE_IO") {
    Some(bitrise_info(env))
  } else if env_has(env, "BUDDY_WORKSPACE_ID") {
    Some(buddy_info(env))
  } else if env_has(env, "BUILDKITE") {
    Some(buildkite_info(env))
  } else if env_has(env, "CIRCLECI") {
    Some(circleci_info(env))
  } else if env_has(env, "CIRRUS_CI") {
    Some(cirrus_info(env))
  } else if env_has(env, "CODEBUILD_BUILD_ID") {
    Some(codebuild_info(env))
  } else if env_has(env, "CF_BUILD_ID") {
    Some(codefresh_info(env))
  } else if env_get(env, "CI_NAME") == Some("codeship") {
    Some(codeship_info(env))
  } else if env_has(env, "DRONE") {
    Some(drone_info(env))
  } else if env_has(env, "GITHUB_ACTION") {
    Some(github_info(env, pr_event=None))
  } else if env_has(env, "GITLAB_CI") {
    Some(gitlab_info(env))
  } else if env_has(env, "JENKINS_URL") {
    Some(jenkins_info(env, git_head=None))
  } else if env_has(env, "SAILCI") {
    Some(sail_info(env))
  } else if env_has(env, "SEMAPHORE") {
    Some(semaphore_info(env, git_head=None))
  } else if env_has(env, "SHIPPABLE") {
    Some(shippable_info(env))
  } else if env_has(env, "TRAVIS") {
    Some(travis_info(env))
  } else if env_has(env, "BUILD_BUILDURI") {
    Some(vsts_info(env))
  } else if env_has(env, "WERCKER_MAIN_PIPELINE_STARTED") {
    Some(wercker_info(env))
  } else {
    None
  }
}

///|
fn appveyor_info(env : Map[String, String]) -> Info {
  let pr = env_get(env, "APPVEYOR_PULL_REQUEST_NUMBER")
  let is_pr = pr is Some(_)
  {
    ..base_info("Appveyor", "appveyor", is_ci=true),
    commit: env_get(env, "APPVEYOR_REPO_COMMIT"),
    tag: env_get(env, "APPVEYOR_REPO_TAG_NAME"),
    build: env_get(env, "APPVEYOR_BUILD_NUMBER"),
    build_url: map2(
      env_get(env, "APPVEYOR_PROJECT_SLUG"),
      env_get(env, "APPVEYOR_BUILD_VERSION"),
      (slug, version) => {
        "https://ci.appveyor.com/project/\{slug}/build/\{version}"
      },
    ),
    branch: env_get(env, "APPVEYOR_REPO_BRANCH"),
    job: env_get(env, "APPVEYOR_JOB_NUMBER"),
    job_url: map2(
      env_get(env, "APPVEYOR_PROJECT_SLUG"),
      env_get(env, "APPVEYOR_JOB_ID"),
      (slug, job) => "https://ci.appveyor.com/project/\{slug}/build/job/\{job}",
    ),
    pr,
    is_pr: Some(is_pr),
    pr_branch: env_get(env, "APPVEYOR_PULL_REQUEST_HEAD_REPO_BRANCH"),
    slug: env_get(env, "APPVEYOR_REPO_NAME"),
    root: env_get(env, "APPVEYOR_BUILD_FOLDER"),
  }
}

///|
fn bamboo_info(env : Map[String, String]) -> Info {
  {
    ..base_info("Bamboo", "bamboo", is_ci=true),
    commit: env_get(env, "bamboo_planRepository_1_revision"),
    build: env_get(env, "bamboo_buildNumber"),
    build_url: env_get(env, "bamboo_buildResultsUrl"),
    branch: env_get(env, "bamboo_planRepository_1_branchName"),
    job: env_get(env, "bamboo_buildKey"),
    root: env_get(env, "bamboo_build_working_directory"),
  }
}

///|
fn bitbucket_info(env : Map[String, String]) -> Info {
  {
    ..base_info("Bitbucket Pipelines", "bitbucket", is_ci=true),
    commit: env_get(env, "BITBUCKET_COMMIT"),
    tag: env_get(env, "BITBUCKET_TAG"),
    build: env_get(env, "BITBUCKET_BUILD_NUMBER"),
    build_url: map2(
      env_get(env, "BITBUCKET_REPO_SLUG"),
      env_get(env, "BITBUCKET_BUILD_NUMBER"),
      (slug, build) => {
        "https://bitbucket.org/\{slug}/addon/pipelines/home#!/results/\{build}"
      },
    ),
    branch: env_get(env, "BITBUCKET_BRANCH"),
    slug: env_get(env, "BITBUCKET_REPO_SLUG"),
    root: env_get(env, "BITBUCKET_CLONE_DIR"),
  }
}

///|
fn bitrise_info(env : Map[String, String]) -> Info {
  let pr = false_string_as_none(env_get(env, "BITRISE_PULL_REQUEST"))
  let is_pr = pr is Some(_)
  {
    ..base_info("Bitrise", "bitrise", is_ci=true),
    commit: env_get(env, "BITRISE_GIT_COMMIT"),
    tag: env_get(env, "BITRISE_GIT_TAG"),
    build: env_get(env, "BITRISE_BUILD_NUMBER"),
    build_url: env_get(env, "BITRISE_BUILD_URL"),
    branch: if is_pr {
      env_get(env, "BITRISEIO_GIT_BRANCH_DEST")
    } else {
      env_get(env, "BITRISE_GIT_BRANCH")
    },
    pr,
    is_pr: Some(is_pr),
    pr_branch: if is_pr {
      env_get(env, "BITRISE_GIT_BRANCH")
    } else {
      None
    },
    slug: env_get(env, "BITRISE_APP_SLUG"),
  }
}

///|
fn buddy_info(env : Map[String, String]) -> Info {
  let pr = last_number(env_get(env, "BUDDY_EXECUTION_PULL_REQUEST_ID"))
  let is_pr = pr is Some(_)
  {
    ..base_info("Buddy", "buddy", is_ci=true),
    commit: env_get(env, "BUDDY_EXECUTION_REVISION"),
    tag: env_get(env, "BUDDY_EXECUTION_TAG"),
    build: env_get(env, "BUDDY_EXECUTION_ID"),
    build_url: env_get(env, "BUDDY_EXECUTION_URL"),
    branch: if is_pr {
      None
    } else {
      env_get(env, "BUDDY_EXECUTION_BRANCH")
    },
    pr,
    is_pr: Some(is_pr),
    slug: env_get(env, "BUDDY_REPO_SLUG"),
  }
}

///|
fn buildkite_info(env : Map[String, String]) -> Info {
  let pr = false_string_as_none(env_get(env, "BUILDKITE_PULL_REQUEST"))
  let is_pr = pr is Some(_)
  {
    ..base_info("Buildkite", "buildkite", is_ci=true),
    build: env_get(env, "BUILDKITE_BUILD_NUMBER"),
    build_url: env_get(env, "BUILDKITE_BUILD_URL"),
    commit: env_get(env, "BUILDKITE_COMMIT"),
    tag: env_get(env, "BUILDKITE_TAG"),
    branch: if is_pr {
      env_get(env, "BUILDKITE_PULL_REQUEST_BASE_BRANCH")
    } else {
      env_get(env, "BUILDKITE_BRANCH")
    },
    slug: join2(
      env_get(env, "BUILDKITE_ORGANIZATION_SLUG"),
      "/",
      env_get(env, "BUILDKITE_PROJECT_SLUG"),
    ),
    pr,
    is_pr: Some(is_pr),
    pr_branch: if is_pr {
      env_get(env, "BUILDKITE_BRANCH")
    } else {
      None
    },
    root: env_get(env, "BUILDKITE_BUILD_CHECKOUT_PATH"),
  }
}

///|
fn circleci_info(env : Map[String, String]) -> Info {
  let pr = match env_get(env, "CIRCLE_PR_NUMBER") {
    Some(value) => Some(value)
    None =>
      last_number(env_first(env, ["CIRCLE_PULL_REQUEST", "CI_PULL_REQUEST"]))
  }
  let is_pr = pr is Some(_)
  {
    ..base_info("CircleCI", "circleci", is_ci=true),
    build: env_get(env, "CIRCLE_BUILD_NUM"),
    build_url: env_get(env, "CIRCLE_BUILD_URL"),
    job: map2(
      env_get(env, "CIRCLE_BUILD_NUM"),
      env_get(env, "CIRCLE_NODE_INDEX"),
      (build, index) => "\{build}.\{index}",
    ),
    commit: env_get(env, "CIRCLE_SHA1"),
    tag: env_get(env, "CIRCLE_TAG"),
    branch: if is_pr {
      None
    } else {
      env_get(env, "CIRCLE_BRANCH")
    },
    pr,
    is_pr: Some(is_pr),
    pr_branch: if is_pr {
      env_get(env, "CIRCLE_BRANCH")
    } else {
      None
    },
    slug: join2(
      env_get(env, "CIRCLE_PROJECT_USERNAME"),
      "/",
      env_get(env, "CIRCLE_PROJECT_REPONAME"),
    ),
  }
}

///|
fn cirrus_info(env : Map[String, String]) -> Info {
  let pr = env_get(env, "CIRRUS_PR")
  let is_pr = pr is Some(_)
  {
    ..base_info("Cirrus CI", "cirrus", is_ci=true),
    commit: env_get(env, "CIRRUS_CHANGE_IN_REPO"),
    tag: env_get(env, "CIRRUS_TAG"),
    build: env_get(env, "CIRRUS_BUILD_ID"),
    build_url: env_get(env, "CIRRUS_BUILD_ID").map(build => {
      "https://cirrus-ci.com/build/\{build}"
    }),
    job: env_get(env, "CIRRUS_TASK_ID"),
    job_url: env_get(env, "CIRRUS_TASK_ID").map(task => {
      "https://cirrus-ci.com/task/\{task}"
    }),
    branch: if is_pr {
      env_get(env, "CIRRUS_BASE_BRANCH")
    } else {
      env_get(env, "CIRRUS_BRANCH")
    },
    pr,
    is_pr: Some(is_pr),
    slug: env_get(env, "CIRRUS_REPO_FULL_NAME"),
    root: env_get(env, "CIRRUS_WORKING_DIR"),
  }
}

///|
fn codebuild_info(env : Map[String, String]) -> Info {
  {
    ..base_info("AWS CodeBuild", "codebuild", is_ci=true),
    build: env_get(env, "CODEBUILD_BUILD_ID"),
    build_url: map2(
      env_get(env, "AWS_REGION"),
      env_get(env, "CODEBUILD_BUILD_ID"),
      (region, build) => {
        "https://console.aws.amazon.com/codebuild/home?region=\{region}#/builds/\{build}/view/new"
      },
    ),
    root: env_get(env, "PWD"),
  }
}

///|
fn codefresh_info(env : Map[String, String]) -> Info {
  let pr = env_get(env, "CF_PULL_REQUEST_NUMBER")
  let is_pr = pr is Some(_)
  {
    ..base_info("Codefresh", "codefresh", is_ci=true),
    commit: env_get(env, "CF_REVISION"),
    build: env_get(env, "CF_BUILD_ID"),
    build_url: env_get(env, "CF_BUILD_URL"),
    branch: if is_pr {
      env_get(env, "CF_PULL_REQUEST_TARGET")
    } else {
      env_get(env, "CF_BRANCH")
    },
    pr,
    is_pr: Some(is_pr),
    pr_branch: if is_pr {
      env_get(env, "CF_BRANCH")
    } else {
      None
    },
    slug: join2(
      env_get(env, "CF_REPO_OWNER"),
      "/",
      env_get(env, "CF_REPO_NAME"),
    ),
    root: env_get(env, "CF_VOLUME_PATH"),
  }
}

///|
fn codeship_info(env : Map[String, String]) -> Info {
  {
    ..base_info("Codeship", "codeship", is_ci=true),
    build: env_get(env, "CI_BUILD_NUMBER"),
    build_url: env_get(env, "CI_BUILD_URL"),
    commit: env_get(env, "CI_COMMIT_ID"),
    branch: env_get(env, "CI_BRANCH"),
    slug: env_get(env, "CI_REPO_NAME"),
  }
}

///|
fn drone_info(env : Map[String, String]) -> Info {
  let is_pr = env_get(env, "DRONE_BUILD_EVENT") == Some("pull_request")
  {
    ..base_info("Drone", "drone", is_ci=true),
    commit: env_get(env, "DRONE_COMMIT_SHA"),
    tag: env_get(env, "DRONE_TAG"),
    build: env_get(env, "DRONE_BUILD_NUMBER"),
    build_url: env_get(env, "DRONE_BUILD_LINK"),
    branch: if is_pr {
      env_get(env, "DRONE_TARGET_BRANCH")
    } else {
      env_get(env, "DRONE_BRANCH")
    },
    job: env_get(env, "DRONE_JOB_NUMBER"),
    job_url: env_get(env, "DRONE_BUILD_LINK"),
    pr: env_get(env, "DRONE_PULL_REQUEST"),
    is_pr: Some(is_pr),
    pr_branch: if is_pr {
      env_get(env, "DRONE_SOURCE_BRANCH")
    } else {
      None
    },
    slug: join2(
      env_get(env, "DRONE_REPO_OWNER"),
      "/",
      env_get(env, "DRONE_REPO_NAME"),
    ),
    root: env_get(env, "DRONE_WORKSPACE"),
  }
}

///|
fn github_info(env : Map[String, String], pr_event~ : GithubPrEvent?) -> Info {
  let is_pr = env_get(env, "GITHUB_EVENT_NAME") == Some("pull_request")
  let ref_branch = branch_from_ref(env_get(env, "GITHUB_REF"))
  let event_branch = match pr_event {
    Some(event) => event.branch
    None => None
  }
  let event_pr = match pr_event {
    Some(event) => event.pr
    None => None
  }
  {
    ..base_info("GitHub Actions", "github", is_ci=true),
    commit: env_get(env, "GITHUB_SHA"),
    is_pr: Some(is_pr),
    branch: if is_pr {
      optional_or(event_branch, ref_branch)
    } else {
      ref_branch
    },
    pr_branch: if is_pr {
      ref_branch
    } else {
      None
    },
    pr: if is_pr {
      event_pr
    } else {
      None
    },
    slug: env_get(env, "GITHUB_REPOSITORY"),
    root: env_get(env, "GITHUB_WORKSPACE"),
  }
}

///|
fn gitlab_info(env : Map[String, String]) -> Info {
  {
    ..base_info("GitLab CI/CD", "gitlab", is_ci=true),
    commit: env_get(env, "CI_COMMIT_SHA"),
    tag: env_get(env, "CI_COMMIT_TAG"),
    build: env_get(env, "CI_PIPELINE_ID"),
    build_url: map2(
      env_get(env, "CI_PROJECT_URL"),
      env_get(env, "CI_PIPELINE_ID"),
      (url, pipeline) => "\{url}/pipelines/\{pipeline}",
    ),
    job: env_get(env, "CI_JOB_ID"),
    job_url: map2(env_get(env, "CI_PROJECT_URL"), env_get(env, "CI_JOB_ID"), (
      url,
      job,
    ) => "\{url}/-/jobs/\{job}"),
    branch: env_get(env, "CI_COMMIT_REF_NAME"),
    slug: env_get(env, "CI_PROJECT_PATH"),
    root: env_get(env, "CI_PROJECT_DIR"),
  }
}

///|
fn jenkins_info(env : Map[String, String], git_head~ : String?) -> Info {
  let pr = env_first(env, ["ghprbPullId", "gitlabMergeRequestId", "CHANGE_ID"])
  let is_pr = pr is Some(_)
  let local_branch = env_first(env, [
    "GIT_LOCAL_BRANCH", "GIT_BRANCH", "gitlabBranch", "BRANCH_NAME",
  ])
  {
    ..base_info("Jenkins", "jenkins", is_ci=true),
    commit: optional_or(
      env_first(env, ["ghprbActualCommit", "GIT_COMMIT"]),
      git_head,
    ),
    branch: if is_pr {
      env_first(env, ["ghprbTargetBranch", "gitlabTargetBranch"])
    } else {
      local_branch
    },
    build: env_get(env, "BUILD_NUMBER"),
    build_url: env_get(env, "BUILD_URL"),
    root: env_get(env, "WORKSPACE"),
    pr,
    is_pr: Some(is_pr),
    pr_branch: if is_pr {
      optional_or(
        env_first(env, ["ghprbSourceBranch", "gitlabSourceBranch"]),
        local_branch,
      )
    } else {
      None
    },
  }
}

///|
fn sail_info(env : Map[String, String]) -> Info {
  let pr = env_get(env, "SAIL_PULL_REQUEST_NUMBER")
  let is_pr = pr is Some(_)
  {
    ..base_info("Sail CI", "sail", is_ci=true),
    commit: env_get(env, "SAIL_COMMIT_SHA"),
    branch: if is_pr {
      None
    } else {
      env_get(env, "SAIL_COMMIT_BRANCH")
    },
    pr,
    is_pr: Some(is_pr),
    slug: join2(
      env_get(env, "SAIL_REPO_OWNER"),
      "/",
      env_get(env, "SAIL_REPO_NAME"),
    ),
    root: env_get(env, "SAIL_CLONE_DIR"),
  }
}

///|
fn semaphore_info(env : Map[String, String], git_head~ : String?) -> Info {
  let pr = env_get(env, "PULL_REQUEST_NUMBER")
  let is_pr = pr is Some(_)
  {
    ..base_info("Semaphore", "semaphore", is_ci=true),
    commit: git_head,
    build: env_get(env, "SEMAPHORE_BUILD_NUMBER"),
    branch: if is_pr {
      None
    } else {
      env_get(env, "BRANCH_NAME")
    },
    pr,
    is_pr: Some(is_pr),
    pr_branch: if is_pr {
      env_get(env, "BRANCH_NAME")
    } else {
      None
    },
    slug: env_get(env, "SEMAPHORE_REPO_SLUG"),
    root: env_get(env, "SEMAPHORE_PROJECT_DIR"),
  }
}

///|
fn shippable_info(env : Map[String, String]) -> Info {
  let pr = if env_get(env, "IS_PULL_REQUEST") == Some("true") {
    env_get(env, "PULL_REQUEST")
  } else {
    None
  }
  let is_pr = pr is Some(_)
  {
    ..base_info("Shippable", "shippable", is_ci=true),
    commit: env_get(env, "COMMIT"),
    tag: env_get(env, "GIT_TAG_NAME"),
    build: env_get(env, "BUILD_NUMBER"),
    build_url: env_get(env, "BUILD_URL"),
    branch: if is_pr {
      env_get(env, "BASE_BRANCH")
    } else {
      env_get(env, "BRANCH")
    },
    job: env_get(env, "JOB_NUMBER"),
    pr,
    is_pr: Some(is_pr),
    pr_branch: if is_pr {
      env_get(env, "HEAD_BRANCH")
    } else {
      None
    },
    slug: env_get(env, "SHIPPABLE_REPO_SLUG"),
    root: env_get(env, "SHIPPABLE_BUILD_DIR"),
  }
}

///|
fn travis_info(env : Map[String, String]) -> Info {
  let pr = false_string_as_none(env_get(env, "TRAVIS_PULL_REQUEST"))
  let is_pr = pr is Some(_)
  {
    ..base_info("Travis CI", "travis", is_ci=true),
    commit: env_get(env, "TRAVIS_COMMIT"),
    tag: env_get(env, "TRAVIS_TAG"),
    build: env_get(env, "TRAVIS_BUILD_NUMBER"),
    build_url: env_get(env, "TRAVIS_BUILD_WEB_URL"),
    branch: env_get(env, "TRAVIS_BRANCH"),
    job: env_get(env, "TRAVIS_JOB_NUMBER"),
    job_url: env_get(env, "TRAVIS_JOB_WEB_URL"),
    pr,
    is_pr: Some(is_pr),
    pr_branch: env_get(env, "TRAVIS_PULL_REQUEST_BRANCH"),
    slug: env_get(env, "TRAVIS_REPO_SLUG"),
    root: env_get(env, "TRAVIS_BUILD_DIR"),
  }
}

///|
fn vsts_info(env : Map[String, String]) -> Info {
  let pr = env_get(env, "SYSTEM_PULLREQUEST_PULLREQUESTID")
  let is_pr = pr is Some(_)
  {
    ..base_info("Visual Studio Team Services", "vsts", is_ci=true),
    commit: env_get(env, "BUILD_SOURCEVERSION"),
    build: env_get(env, "BUILD_BUILDNUMBER"),
    branch: if is_pr {
      env_get(env, "SYSTEM_PULLREQUEST_TARGETBRANCH")
    } else {
      env_get(env, "BUILD_SOURCEBRANCHNAME")
    },
    pr,
    is_pr: Some(is_pr),
    pr_branch: if is_pr {
      env_get(env, "SYSTEM_PULLREQUEST_SOURCEBRANCH")
    } else {
      None
    },
    root: env_get(env, "BUILD_REPOSITORY_LOCALPATH"),
  }
}

///|
fn wercker_info(env : Map[String, String]) -> Info {
  {
    ..base_info("Wercker", "wercker", is_ci=true),
    commit: env_get(env, "WERCKER_GIT_COMMIT"),
    build: env_get(env, "WERCKER_MAIN_PIPELINE_STARTED"),
    build_url: env_get(env, "WERCKER_RUN_URL"),
    branch: env_get(env, "WERCKER_GIT_BRANCH"),
    slug: join2(
      env_get(env, "WERCKER_GIT_OWNER"),
      "/",
      env_get(env, "WERCKER_GIT_REPOSITORY"),
    ),
    root: env_get(env, "WERCKER_ROOT"),
  }
}
