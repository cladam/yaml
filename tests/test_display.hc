import "../src/yaml"

test "yaml_show bool lowercase" {
  assert(yaml_show(YBool(true)) == "true")
  assert(yaml_show(YBool(false)) == "false")
}
