import "../src/yaml"

// --- Literal block scalars ---

test "literal block preserves newlines" {
  let doc = yaml_parse("msg: |\n  line1\n  line2\n  line3") |> yaml_ok
  let msg = doc |> at("msg") |> as_str
  assert(msg == Some("line1\nline2\nline3\n"))
}

test "literal block strip chomp" {
  let doc = yaml_parse("msg: |-\n  hello\n  world") |> yaml_ok
  let msg = doc |> at("msg") |> as_str
  assert(msg == Some("hello\nworld"))
}

test "literal block keep chomp" {
  let doc = yaml_parse("msg: |+\n  hello\n  world") |> yaml_ok
  let msg = doc |> at("msg") |> as_str
  assert(msg == Some("hello\nworld\n"))
}

test "literal block with deeper indent" {
  let doc = yaml_parse("script: |\n    echo hello\n    echo world") |> yaml_ok
  let script = doc |> at("script") |> as_str
  assert(script == Some("echo hello\necho world\n"))
}

// --- Folded block scalars ---

test "folded block joins lines with spaces" {
  let doc = yaml_parse("msg: >\n  this is\n  a long\n  message") |> yaml_ok
  let msg = doc |> at("msg") |> as_str
  assert(msg == Some("this is a long message\n"))
}

test "folded block strip chomp" {
  let doc = yaml_parse("msg: >-\n  hello\n  world") |> yaml_ok
  let msg = doc |> at("msg") |> as_str
  assert(msg == Some("hello world"))
}

test "folded block keep chomp" {
  let doc = yaml_parse("msg: >+\n  hello\n  world") |> yaml_ok
  let msg = doc |> at("msg") |> as_str
  assert(msg == Some("hello world\n"))
}

// --- Block scalars in context ---

test "literal block alongside other keys" {
  let doc = yaml_parse("name: test\nscript: |\n  line1\n  line2\nversion: 1") |> yaml_ok
  let name = doc |> at("name") |> as_str
  let script = doc |> at("script") |> as_str
  let ver = doc |> at("version") |> as_int
  assert(name == Some("test"))
  assert(script == Some("line1\nline2\n"))
  assert(ver == Some(1))
}

// --- Comments in flow collections ---

test "comment in flow sequence" {
  let doc = yaml_parse("items: [a, b, c]") |> yaml_ok
  let items = doc |> at("items")
  assert(yaml_length(items) == 3)
}

test "comment after flow sequence" {
  let doc = yaml_parse("items: [a, b] # a list") |> yaml_ok
  let items = doc |> at("items")
  assert(yaml_length(items) == 2)
  let a = items |> nth(0) |> as_str
  assert(a == Some("a"))
}

test "comment preserves flow content inside brackets" {
  let doc = yaml_parse("items: [x, y] # ignore") |> yaml_ok
  let b = doc |> at("items") |> nth(1) |> as_str
  assert(b == Some("y"))
}
