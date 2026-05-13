import "../src/yaml"

test "empty input returns error" {
  assert(is_err(yaml_parse("")))
}
