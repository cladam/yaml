import "../src/yaml_types"
import "../src/display"

test "yaml_show bool lowercase" {
  assert(yaml_show(YBool(true)) == "true")
  assert(yaml_show(YBool(false)) == "false")
}
