import "../src/yaml_types"
import "../src/scalar"
import "../src/parser"
import "../src/api"

// --- Null from empty value ---

test "empty value resolves to null" {
  let doc = yaml_parse("name:") |> yaml_ok
  let val = doc |> at("name")
  match val {
    Some(YNull) => assert(true),
    _ => assert(false)
  }
}

test "empty value in nested map" {
  let doc = yaml_parse("config:\n  host:\n  port: 80") |> yaml_ok
  let host = doc |> at("config") |> at("host")
  match host {
    Some(YNull) => assert(true),
    _ => assert(false)
  }
}

// --- Document markers ---

test "document start marker stripped" {
  let doc = yaml_parse("---\nname: test") |> yaml_ok
  let name = doc |> at("name") |> as_str
  assert(name == Some("test"))
}

test "document end marker stripped" {
  let doc = yaml_parse("name: test\n...") |> yaml_ok
  let name = doc |> at("name") |> as_str
  assert(name == Some("test"))
}

test "both document markers stripped" {
  let doc = yaml_parse("---\nname: test\n...") |> yaml_ok
  let name = doc |> at("name") |> as_str
  assert(name == Some("test"))
}

test "document markers with block content" {
  let doc = yaml_parse("---\ndb:\n  host: localhost\n  port: 5432\n...") |> yaml_ok
  let host = doc |> at("db") |> at("host") |> as_str
  let port = doc |> at("db") |> at("port") |> as_int
  assert(host == Some("localhost"))
  assert(port == Some(5432))
}

// --- Trailing commas ---

test "trailing comma in flow sequence" {
  let doc = yaml_parse("items: [a, b,]") |> yaml_ok
  let items = doc |> at("items")
  assert(yaml_length(items) == 2)
  let a = items |> nth(0) |> as_str
  let b = items |> nth(1) |> as_str
  assert(a == Some("a"))
  assert(b == Some("b"))
}

test "trailing comma in flow mapping" {
  let input = join(["data: ", "{", "x: 1, y: 2,", "}"], "")
  let doc = yaml_parse(input) |> yaml_ok
  let x = doc |> at("data") |> at("x") |> as_int
  let y = doc |> at("data") |> at("y") |> as_int
  assert(x == Some(1))
  assert(y == Some(2))
}

// --- Empty lines ---

test "empty lines between entries" {
  let doc = yaml_parse("a: 1\n\nb: 2\n\nc: 3") |> yaml_ok
  let a = doc |> at("a") |> as_int
  let c = doc |> at("c") |> as_int
  assert(a == Some(1))
  assert(c == Some(3))
}
