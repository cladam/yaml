import "../src/yaml"

// --- Pipe navigation ---

test "pipe at chain" {
  let input = "database:\n  host: localhost\n  port: 5432"
  let doc = yaml_parse(input) |> yaml_ok
  let host = doc |> at("database") |> at("host") |> as_str
  assert(host == Some("localhost"))
  let port = doc |> at("database") |> at("port") |> as_int
  assert(port == Some(5432))
}

test "pipe with defaults" {
  let input = "name: myapp\nport: 8080"
  let doc = yaml_parse(input) |> yaml_ok
  assert(str_or(doc |> at("name"), "unknown") == "myapp")
  assert(int_or(doc |> at("port"), 3000) == 8080)
  assert(str_or(doc |> at("missing"), "fallback") == "fallback")
  assert(int_or(doc |> at("missing"), 42) == 42)
}

test "pipe nth on list" {
  let input = "- apple\n- banana\n- cherry"
  let doc = yaml_parse(input) |> yaml_ok
  let first = doc |> nth(0) |> as_str
  assert(first == Some("apple"))
  let third = doc |> nth(2) |> as_str
  assert(third == Some("cherry"))
  let oob = doc |> nth(5) |> as_str
  assert(oob == None)
}

test "pipe nested list in map" {
  let input = "fruits:\n  - apple\n  - banana"
  let doc = yaml_parse(input) |> yaml_ok
  let fruits = doc |> at("fruits")
  let first = fruits |> nth(0) |> as_str
  assert(first == Some("apple"))
  let second = fruits |> nth(1) |> as_str
  assert(second == Some("banana"))
}

// --- Inspection ---

test "pipe has_key" {
  let input = "name: test\nport: 80"
  let doc = yaml_parse(input) |> yaml_ok
  assert(has_key(doc, "name") == true)
  assert(has_key(doc, "missing") == false)
}

test "pipe keys" {
  let input = "name: test\nport: 80"
  let doc = yaml_parse(input) |> yaml_ok
  assert(length(keys(doc)) == 2)
  assert(length(keys(doc |> at("nonexistent"))) == 0)
}

test "pipe yaml_length" {
  let input = "- a\n- b\n- c"
  let doc = yaml_parse(input) |> yaml_ok
  assert(yaml_length(doc) == 3)
  assert(yaml_length(doc |> nth(0)) == 0)
}

// --- Edge cases ---

test "pipe missing key returns None" {
  let input = "name: test"
  let doc = yaml_parse(input) |> yaml_ok
  let deep = doc |> at("missing") |> at("deep") |> as_str
  assert(deep == None)
}

test "pipe error result" {
  let doc = yaml_parse("") |> yaml_ok
  let val = doc |> at("anything") |> as_str
  assert(val == None)
}
