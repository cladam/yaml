import "../src/yaml"

// --- Multi-line plain scalars ---

test "multi-line plain scalar in map" {
  let input = "description: This is a long\n  description text"
  let doc = yaml_parse(input) |> yaml_ok
  let desc = doc |> at("description") |> as_str
  assert(desc == Some("This is a long description text"))
}

test "multi-line plain scalar with multiple continuations" {
  let input = "msg: line one\n  line two\n  line three"
  let doc = yaml_parse(input) |> yaml_ok
  let msg = doc |> at("msg") |> as_str
  assert(msg == Some("line one line two line three"))
}

test "multi-line plain scalar alongside other keys" {
  let input = "title: Hello\n  World\nversion: 1"
  let doc = yaml_parse(input) |> yaml_ok
  let title = doc |> at("title") |> as_str
  let ver = doc |> at("version") |> as_int
  assert(title == Some("Hello World"))
  assert(ver == Some(1))
}

test "multi-line plain scalar in list" {
  let input = "- This is a long\n  description text"
  let doc = yaml_parse(input) |> yaml_ok
  let first = doc |> nth(0) |> as_str
  assert(first == Some("This is a long description text"))
}

// --- Multi-line quoted scalars ---

test "multi-line double-quoted scalar in map" {
  let input = "msg: \"hello\n  world\""
  let doc = yaml_parse(input) |> yaml_ok
  let msg = doc |> at("msg") |> as_str
  assert(msg == Some("hello world"))
}

test "multi-line single-quoted scalar in map" {
  let input = "msg: 'hello\n  world'"
  let doc = yaml_parse(input) |> yaml_ok
  let msg = doc |> at("msg") |> as_str
  assert(msg == Some("hello world"))
}

test "multi-line double-quoted scalar in list" {
  let input = "- \"hello\n  world\""
  let doc = yaml_parse(input) |> yaml_ok
  let first = doc |> nth(0) |> as_str
  assert(first == Some("hello world"))
}

// --- Block indentation indicators ---

test "literal block with explicit indent |2" {
  let input = "content: |2\n    extra spaces\n    here"
  let doc = yaml_parse(input) |> yaml_ok
  let content = doc |> at("content") |> as_str
  assert(content == Some("  extra spaces\n  here\n"))
}

test "folded block with explicit indent >2" {
  let input = "msg: >2\n    hello\n    world"
  let doc = yaml_parse(input) |> yaml_ok
  let msg = doc |> at("msg") |> as_str
  assert(msg == Some("  hello   world\n"))
}

test "block with indent and strip chomp |2-" {
  let input = "content: |2-\n    line1\n    line2"
  let doc = yaml_parse(input) |> yaml_ok
  let content = doc |> at("content") |> as_str
  assert(content == Some("  line1\n  line2"))
}

test "block with chomp then indent |-2" {
  let input = "content: |-2\n    line1\n    line2"
  let doc = yaml_parse(input) |> yaml_ok
  let content = doc |> at("content") |> as_str
  assert(content == Some("  line1\n  line2"))
}

// --- Block scalars in list entries ---

test "literal block scalar in list" {
  let input = "- |\n  line1\n  line2"
  let doc = yaml_parse(input) |> yaml_ok
  let first = doc |> nth(0) |> as_str
  assert(first == Some("line1\nline2\n"))
}

test "folded block scalar in list" {
  let input = "- >\n  hello\n  world"
  let doc = yaml_parse(input) |> yaml_ok
  let first = doc |> nth(0) |> as_str
  assert(first == Some("hello world\n"))
}

test "block scalar in list alongside plain items" {
  let input = "- first\n- |\n  line1\n  line2\n- third"
  let doc = yaml_parse(input) |> yaml_ok
  let a = doc |> nth(0) |> as_str
  let b = doc |> nth(1) |> as_str
  let c = doc |> nth(2) |> as_str
  assert(a == Some("first"))
  assert(b == Some("line1\nline2\n"))
  assert(c == Some("third"))
}
