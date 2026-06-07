///|
/// Return a non-empty environment variable from `env`.
fn env_get(env : Map[String, String], key : String) -> String? {
  match env.get(key) {
    Some(value) if value != "" => Some(value)
    _ => None
  }
}

///|
/// Return whether a non-empty environment variable exists.
fn env_has(env : Map[String, String], key : String) -> Bool {
  env_get(env, key) is Some(_)
}

///|
/// Return the first non-empty value for `keys`.
fn env_first(env : Map[String, String], keys : Array[String]) -> String? {
  for key in keys {
    match env_get(env, key) {
      Some(value) => return Some(value)
      None => ()
    }
  }
  None
}

///|
/// Build a string from parts only when every part is present.
fn join2(a : String?, separator : String, b : String?) -> String? {
  match (a, b) {
    (Some(left), Some(right)) => Some("\{left}\{separator}\{right}")
    _ => None
  }
}

///|
/// Build a URL from a template's required parts.
fn[A, B] map2(a : A?, b : B?, f : (A, B) -> String) -> String? {
  match (a, b) {
    (Some(left), Some(right)) => Some(f(left, right))
    _ => None
  }
}

///|
/// Return `None` for CI variables that spell "not a pull request" as `false`.
fn false_string_as_none(value : String?) -> String? {
  match value {
    Some("false") => None
    other => other
  }
}

///|
/// Extract the last decimal number sequence from `value`.
fn last_number(value : String?) -> String? {
  match value {
    None => None
    Some(text) => {
      let mut current = ""
      let mut last = ""
      for char in text {
        if char.is_ascii_digit() {
          current = current + char.to_string()
        } else if current != "" {
          last = current
          current = ""
        }
      }
      if current != "" {
        last = current
      }
      if last == "" {
        None
      } else {
        Some(last)
      }
    }
  }
}

///|
/// Return `left` when present, otherwise `right`.
fn optional_or(left : String?, right : String?) -> String? {
  match left {
    Some(_) => left
    None => right
  }
}

///|
/// Parse a GitHub-style ref into a branch-like name.
fn branch_from_ref(git_ref : String?) -> String? {
  match git_ref {
    Some(value) =>
      match value.strip_prefix("refs/heads/") {
        Some(branch) => Some(branch.to_owned())
        None =>
          match value.strip_prefix("refs/tags/") {
            Some(_) => None
            None =>
              if value == "" || value.has_prefix("refs/") {
                None
              } else {
                Some(value)
              }
          }
      }
    None => None
  }
}
