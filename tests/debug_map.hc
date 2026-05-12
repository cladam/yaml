import "../src/yaml"

test "debug one match" {
  let input = "name: my-project\nversion: 1"
  match yaml_parse(input) {
    Ok(doc) => {
      match yaml_get(doc, "name") {
        Some(YStr(s)) => assert(s == "my-project"),
        _ => assert(false)
      }
    },
    _ => assert(false)
  }
}

test "debug two matches" {
  let input = "name: my-project\nversion: 1"
  match yaml_parse(input) {
    Ok(doc) => {
      match yaml_get(doc, "name") {
        Some(YStr(s)) => assert(s == "my-project"),
        _ => assert(false)
      }
      match yaml_get(doc, "version") {
        Some(YInt(n)) => assert(n == 1),
        _ => assert(false)
      }
    },
    _ => assert(false)
  }
}
