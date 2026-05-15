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

// --- Flow scalar line folding ---

test "double-quoted flow scalar blank line folds to newline" {
  let input = "key: \"line one\n\n  line two\""
  let doc = yaml_parse(input) |> yaml_ok
  let val = doc |> at("key") |> as_str
  assert(val == Some("line one\nline two"))
}

test "single-quoted flow scalar blank line folds to newline" {
  let input = "key: 'line one\n\n  line two'"
  let doc = yaml_parse(input) |> yaml_ok
  let val = doc |> at("key") |> as_str
  assert(val == Some("line one\nline two"))
}

test "double-quoted flow scalar multiple blank lines" {
  let input = "key: \"first\n\n\n  second\""
  let doc = yaml_parse(input) |> yaml_ok
  let val = doc |> at("key") |> as_str
  assert(val == Some("first\n\nsecond"))
}

test "flow scalar in list with blank line" {
  let input = "- \"hello\n\n  world\""
  let doc = yaml_parse(input) |> yaml_ok
  let val = doc |> nth(0) |> as_str
  assert(val == Some("hello\nworld"))
}

// --- Comments between multi-line scalars ---

test "comment line between plain scalar continuations" {
  let input = "key: hello\n  # a comment\n  world"
  let doc = yaml_parse(input) |> yaml_ok
  let val = doc |> at("key") |> as_str
  assert(val == Some("hello world"))
}

test "inline comment on plain scalar continuation" {
  let input = "key: hello\n  world # comment"
  let doc = yaml_parse(input) |> yaml_ok
  let val = doc |> at("key") |> as_str
  assert(val == Some("hello world"))
}

test "comment between map entries with multi-line values" {
  let input = "a: one\n  two\n# between\nb: three"
  let doc = yaml_parse(input) |> yaml_ok
  let a = doc |> at("a") |> as_str
  let b = doc |> at("b") |> as_str
  assert(a == Some("one two"))
  assert(b == Some("three"))
}

test "comment between list items" {
  let input = "- first\n# comment\n- second"
  let doc = yaml_parse(input) |> yaml_ok
  let a = doc |> nth(0) |> as_str
  let b = doc |> nth(1) |> as_str
  assert(a == Some("first"))
  assert(b == Some("second"))
}

// --- Empty line handling inside scalars ---

test "literal block scalar with blank line" {
  let input = "key: |\n  line 1\n\n  line 2"
  let doc = yaml_parse(input) |> yaml_ok
  let val = doc |> at("key") |> as_str
  assert(val == Some("line 1\n\nline 2\n"))
}

test "folded block scalar with blank line" {
  let input = "key: >\n  para 1\n\n  para 2"
  let doc = yaml_parse(input) |> yaml_ok
  let val = doc |> at("key") |> as_str
  assert(val == Some("para 1\n\npara 2\n"))
}

test "literal block in list with blank line" {
  let input = "- |\n  a\n\n  b"
  let doc = yaml_parse(input) |> yaml_ok
  let val = doc |> nth(0) |> as_str
  assert(val == Some("a\n\nb\n"))
}

test "literal block with multiple blank lines" {
  let input = "key: |\n  one\n\n\n  two"
  let doc = yaml_parse(input) |> yaml_ok
  let val = doc |> at("key") |> as_str
  assert(val == Some("one\n\n\ntwo\n"))
}
