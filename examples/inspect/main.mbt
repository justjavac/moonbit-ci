///|
/// Prints the detected CI service and selected repository metadata.
async fn main {
  let info = @ci.env_ci()
  println("CI: \{info.is_ci}")
  println("Service: \{info.name} (\{info.service})")
  match info.slug {
    Some(slug) => println("Repository: \{slug}")
    None => ()
  }
  match info.branch {
    Some(branch) => println("Branch: \{branch}")
    None => ()
  }
  match info.commit {
    Some(commit) => println("Commit: \{commit}")
    None => ()
  }
}
