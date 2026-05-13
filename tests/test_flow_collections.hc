import "../src/yaml"

test "inline empty list" {
  let input = "items: []"
  match yaml_parse(input) {
    Ok(doc) => {
      match yaml_get(doc, "items") {
        Some(v) => {
          match yaml_list(v) {
            Some(items) => assert(length(items) == 0),
            _ => assert(false)
          }
        },
        _ => assert(false)
      }
    },
    _ => assert(false)
  }
}
