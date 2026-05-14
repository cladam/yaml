import "../src/yaml_types"
import "../src/scalar"
import "../src/parser"
import "../src/api"

// ============================================================
// Flow sequences
// ============================================================

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

test "flow sequence with strings" {
  let input = "tags: [alpha, beta, gamma]"
  let tags = yaml_parse(input) |> yaml_ok |> at("tags")
  let first = tags |> nth(0) |> as_str
  let second = tags |> nth(1) |> as_str
  let third = tags |> nth(2) |> as_str
  assert(first == Some("alpha"))
  assert(second == Some("beta"))
  assert(third == Some("gamma"))
}

test "flow sequence with integers" {
  let input = "ports: [80, 443, 8080]"
  let ports = yaml_parse(input) |> yaml_ok |> at("ports")
  let first = ports |> nth(0) |> as_int
  let third = ports |> nth(2) |> as_int
  assert(first == Some(80))
  assert(third == Some(8080))
  assert(yaml_length(ports) == 3)
}

test "flow sequence with mixed types" {
  let input = "data: [hello, 42, true, null]"
  let data = yaml_parse(input) |> yaml_ok |> at("data")
  let s = data |> nth(0) |> as_str
  let i = data |> nth(1) |> as_int
  let b = data |> nth(2) |> as_bool
  assert(s == Some("hello"))
  assert(i == Some(42))
  assert(b == Some(true))
  assert(yaml_length(data) == 4)
}

test "flow sequence single element" {
  let input = "items: [only]"
  let items = yaml_parse(input) |> yaml_ok |> at("items")
  let first = items |> nth(0) |> as_str
  assert(first == Some("only"))
  assert(yaml_length(items) == 1)
}

test "nested flow sequences" {
  let input = "matrix: [[1, 2], [3, 4]]"
  let matrix = yaml_parse(input) |> yaml_ok |> at("matrix")
  let first_row = matrix |> nth(0)
  let val = first_row |> nth(0) |> as_int
  assert(val == Some(1))
  assert(yaml_length(matrix) == 2)
}

// ============================================================
// Flow mappings
// ============================================================

test "empty flow mapping" {
  let input = join(["config: ", "{", "}"], "")
  let config = yaml_parse(input) |> yaml_ok |> at("config")
  assert(yaml_length(config) == 0)
}

test "flow mapping with values" {
  let input = join(["db: ", "{", "host: localhost, port: 5432", "}"], "")
  let host = yaml_parse(input) |> yaml_ok |> at("db") |> at("host") |> as_str
  let port = yaml_parse(input) |> yaml_ok |> at("db") |> at("port") |> as_int
  assert(host == Some("localhost"))
  assert(port == Some(5432))
}

test "flow mapping single entry" {
  let input = join(["meta: ", "{", "name: test", "}"], "")
  let name = yaml_parse(input) |> yaml_ok |> at("meta") |> at("name") |> as_str
  assert(name == Some("test"))
}

test "flow mapping with nested flow sequence" {
  let input = join(["config: ", "{", "tags: [a, b]", "}"], "")
  let tags = yaml_parse(input) |> yaml_ok |> at("config") |> at("tags")
  let a = tags |> nth(0) |> as_str
  let b = tags |> nth(1) |> as_str
  assert(a == Some("a"))
  assert(b == Some("b"))
}

test "flow sequence in block list" {
  let input = "matrix:\n  - [1, 2]\n  - [3, 4]"
  let first = yaml_parse(input) |> yaml_ok |> at("matrix") |> nth(0)
  let val = first |> nth(0) |> as_int
  assert(val == Some(1))
}
