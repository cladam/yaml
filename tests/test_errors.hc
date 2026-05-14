import "../src/yaml_types"
import "../src/scalar"
import "../src/parser"

test "empty input returns error" {
  assert(is_err(yaml_parse("")))
}
