///|
/// CI environment details collected from well-known provider variables.
///
/// Fields that a provider cannot expose are `None`. The `name` field is the
/// human-readable service name and `service` is a stable lowercase identifier.
/// `is_ci` is always present so callers can distinguish a local git fallback
/// from a real CI service.
pub(all) struct Info {
  name : String
  service : String
  is_ci : Bool
  commit : String?
  tag : String?
  build : String?
  build_url : String?
  branch : String?
  job : String?
  job_url : String?
  is_pr : Bool?
  pr : String?
  pr_branch : String?
  slug : String?
  root : String?
} derive(Eq, ToJson, Debug)

///|
/// Return an empty result for a named provider.
fn base_info(name : String, service : String, is_ci~ : Bool) -> Info {
  {
    name,
    service,
    is_ci,
    commit: None,
    tag: None,
    build: None,
    build_url: None,
    branch: None,
    job: None,
    job_url: None,
    is_pr: None,
    pr: None,
    pr_branch: None,
    slug: None,
    root: None,
  }
}
