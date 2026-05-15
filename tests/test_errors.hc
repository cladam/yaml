import "../src/yaml"

test "empty input returns error" {
  assert(is_err(yaml_parse("")))
}

test "tab error includes line number" {
  let input = "name: test\n\tport: 80"
  match yaml_parse(input) {
    Err(msg) => assert(contains(msg, "line 2")),
    Ok(_) => assert(false)
  }
}

test "tab error on first line" {
  let input = "\tname: test"
  match yaml_parse(input) {
    Err(msg) => assert(contains(msg, "line 1")),
    Ok(_) => assert(false)
  }
}

test "yaml_parse_file with valid file" {
  match yaml_parse_file("examples/sample.yml") {
    Ok(doc) => assert(is_some(yaml_get(doc, "name"))),
    Err(_) => assert(false)
  }
}

test "yaml_parse_file with missing file" {
  assert(is_err(yaml_parse_file("nonexistent.yml")))
}