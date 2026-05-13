import "../src/yaml"

test "pipe 2 chain" {
  let doc = yaml_parse("name: test") |> yaml_ok
  let name = doc |> at("name") |> as_str
  assert(name == Some("test"))
}

test "pipe 3 chain at" {
  let input = "db:\n  host: localhost"
  let doc = yaml_parse(input) |> yaml_ok
  let host = doc |> at("db") |> at("host") |> as_str
  assert(host == Some("localhost"))
}

test "pipe nth chain" {
  let input = "- apple\n- banana"
  let doc = yaml_parse(input) |> yaml_ok
  let first = doc |> nth(0)
  let name = first |> as_str
  assert(name == Some("apple"))
}

test "pipe nth inline" {
  let input = "- apple\n- banana"
  let doc = yaml_parse(input) |> yaml_ok
  let name = doc |> nth(0) |> as_str
  assert(name == Some("apple"))
}
