import "../src/yaml"

// ============================================================
// Block-style emission
// ============================================================

test "emit simple string" {
  let y = YStr("hello")
  assert(yaml_emit(y) == "hello")
}

test "emit string needing quotes" {
  let y = YStr("has: colon")
  assert(yaml_emit(y) == "\"has: colon\"")
}

test "emit empty string" {
  let y = YStr("")
  assert(yaml_emit(y) == "\"\"")
}

test "emit null-like string" {
  let y = YStr("null")
  assert(yaml_emit(y) == "\"null\"")
}

test "emit bool-like string" {
  let y = YStr("true")
  assert(yaml_emit(y) == "\"true\"")
}

test "emit string with newline" {
  let y = YStr("line1\nline2")
  assert(yaml_emit(y) == "\"line1\\nline2\"")
}

test "emit integer" {
  let y = YInt(42)
  assert(yaml_emit(y) == "42")
}

test "emit negative integer" {
  let y = YInt(0 - 7)
  assert(yaml_emit(y) == "-7")
}

test "emit float" {
  let y = YFloat(1.0)
  let r = yaml_emit(y)
  assert(r == "1.0" || r == "1" || r == "1.0e0")
}

test "emit bool" {
  assert(yaml_emit(YBool(true)) == "true")
  assert(yaml_emit(YBool(false)) == "false")
}

test "emit null" {
  assert(yaml_emit(YNull) == "null")
}

test "emit flat map" {
  let y = YMap([("name", YStr("alice")), ("age", YInt(30))])
  let expected = "name: alice\nage: 30"
  assert(yaml_emit(y) == expected)
}

test "emit flat list" {
  let y = YList([YStr("a"), YStr("b"), YStr("c")])
  let expected = "- a\n- b\n- c"
  assert(yaml_emit(y) == expected)
}

test "emit nested map" {
  let inner = YMap([("host", YStr("localhost")), ("port", YInt(5432))])
  let y = YMap([("database", inner)])
  let expected = "database:\n  host: localhost\n  port: 5432"
  assert(yaml_emit(y) == expected)
}

test "emit list under map key" {
  let items = YList([YStr("x"), YStr("y")])
  let y = YMap([("tags", items)])
  let expected = "tags:\n  - x\n  - y"
  assert(yaml_emit(y) == expected)
}

test "emit map key needing quotes" {
  let y = YMap([("has: colon", YStr("val"))])
  let expected = "\"has: colon\": val"
  assert(yaml_emit(y) == expected)
}

// ============================================================
// Flow-style emission
// ============================================================

test "emit flow scalar" {
  assert(yaml_emit_flow(YStr("hello")) == "hello")
  assert(yaml_emit_flow(YInt(42)) == "42")
  assert(yaml_emit_flow(YNull) == "null")
}

test "emit flow list" {
  let y = YList([YStr("a"), YInt(1), YBool(true)])
  assert(yaml_emit_flow(y) == "[a, 1, true]")
}

test "emit flow empty list" {
  let y = YList([])
  assert(yaml_emit_flow(y) == "[]")
}

test "emit flow map" {
  let y = YMap([("name", YStr("bob")), ("age", YInt(25))])
  let expected = join(["{", "name: bob, age: 25", "}"], "")
  assert(yaml_emit_flow(y) == expected)
}

test "emit flow nested" {
  let inner = YList([YInt(1), YInt(2)])
  let y = YMap([("nums", inner)])
  let expected = join(["{", "nums: [1, 2]", "}"], "")
  assert(yaml_emit_flow(y) == expected)
}

// ============================================================
// Round-trip tests
// ============================================================

test "round-trip simple map" {
  let y = YMap([("name", YStr("alice")), ("age", YInt(30))])
  let r = yaml_parse(yaml_emit(y)) |> yaml_ok |> at("name") |> as_str
  assert(r == Some("alice"))
}

test "round-trip nested structure" {
  let inner = YMap([("host", YStr("localhost")), ("port", YInt(5432))])
  let y = YMap([("db", inner)])
  let r = yaml_parse(yaml_emit(y)) |> yaml_ok |> at("db") |> at("host") |> as_str
  assert(r == Some("localhost"))
}
