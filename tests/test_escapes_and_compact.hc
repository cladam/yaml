import "../src/yaml_types"
import "../src/scalar"
import "../src/parser"
import "../src/api"

// --- Double-quoted escape sequences ---

test "escape newline in double-quoted string" {
  let doc = yaml_parse("msg: \"hello\\nworld\"") |> yaml_ok
  let msg = doc |> at("msg") |> as_str
  assert(msg == Some("hello\nworld"))
}

test "escape tab in double-quoted string" {
  let doc = yaml_parse("msg: \"col1\\tcol2\"") |> yaml_ok
  let msg = doc |> at("msg") |> as_str
  assert(msg == Some("col1\tcol2"))
}

test "escape backslash in double-quoted string" {
  let doc = yaml_parse("path: \"C:\\\\Users\"") |> yaml_ok
  let path = doc |> at("path") |> as_str
  assert(path == Some("C:\\Users"))
}

test "escape double quote in double-quoted string" {
  let doc = yaml_parse("msg: \"say \\\"hello\\\"\"") |> yaml_ok
  let msg = doc |> at("msg") |> as_str
  assert(msg == Some("say \"hello\""))
}

test "escape slash in double-quoted string" {
  let doc = yaml_parse("url: \"a\\/b\"") |> yaml_ok
  let url = doc |> at("url") |> as_str
  assert(url == Some("a/b"))
}

test "multiple escapes in one string" {
  let doc = yaml_parse("msg: \"line1\\nline2\\ttab\"") |> yaml_ok
  let msg = doc |> at("msg") |> as_str
  assert(msg == Some("line1\nline2\ttab"))
}

// --- Single-quoted escape ---

test "single-quote escape produces apostrophe" {
  let doc = yaml_parse("msg: 'it''s fine'") |> yaml_ok
  let msg = doc |> at("msg") |> as_str
  assert(msg == Some("it's fine"))
}

test "no escape processing in single-quoted strings" {
  let doc = yaml_parse("msg: 'hello\\nworld'") |> yaml_ok
  let msg = doc |> at("msg") |> as_str
  assert(msg == Some("hello\\nworld"))
}

// --- Compact nested mappings ---

test "single compact mapping in list" {
  let doc = yaml_parse("items:\n  - name: foo\n  - name: bar") |> yaml_ok
  let items = doc |> at("items")
  let n0 = items |> nth(0) |> at("name") |> as_str
  let n1 = items |> nth(1) |> at("name") |> as_str
  assert(n0 == Some("foo"))
  assert(n1 == Some("bar"))
}

test "multi-key compact mapping in list" {
  let doc = yaml_parse("people:\n  - name: Alice\n    age: 30\n  - name: Bob\n    age: 25") |> yaml_ok
  let people = doc |> at("people")
  let name0 = people |> nth(0) |> at("name") |> as_str
  let age0 = people |> nth(0) |> at("age") |> as_int
  let name1 = people |> nth(1) |> at("name") |> as_str
  let age1 = people |> nth(1) |> at("age") |> as_int
  assert(name0 == Some("Alice"))
  assert(age0 == Some(30))
  assert(name1 == Some("Bob"))
  assert(age1 == Some(25))
}

test "compact mapping with nested value" {
  let doc = yaml_parse("servers:\n  - host: localhost\n    port: 8080\n  - host: remote\n    port: 9090") |> yaml_ok
  let h0 = doc |> at("servers") |> nth(0) |> at("host") |> as_str
  let p1 = doc |> at("servers") |> nth(1) |> at("port") |> as_int
  assert(h0 == Some("localhost"))
  assert(p1 == Some(9090))
}

test "mixed list items: compact maps and scalars" {
  let doc = yaml_parse("items:\n  - name: foo\n  - plain value\n  - name: bar") |> yaml_ok
  let items = doc |> at("items")
  let n0 = items |> nth(0) |> at("name") |> as_str
  let v1 = items |> nth(1) |> as_str
  let n2 = items |> nth(2) |> at("name") |> as_str
  assert(n0 == Some("foo"))
  assert(v1 == Some("plain value"))
  assert(n2 == Some("bar"))
}
