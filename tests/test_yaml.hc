import "../src/yaml"

test "parse positive integer" {
  match yaml_parse("42") {
    Ok(YInt(n)) => assert(n == 42),
    _ => assert(false)
  }
}

test "parse negative integer" {
  match yaml_parse("-7") {
    Ok(YInt(n)) => assert(n == -7),
    _ => assert(false)
  }
}

test "parse zero" {
  match yaml_parse("0") {
    Ok(YInt(n)) => assert(n == 0),
    _ => assert(false)
  }
}

test "parse integer with whitespace" {
  match yaml_parse("  99  ") {
    Ok(YInt(n)) => assert(n == 99),
    _ => assert(false)
  }
}

test "non-integer falls back to string" {
  match yaml_parse("hello") {
    Ok(YStr(s)) => assert(s == "hello"),
    _ => assert(false)
  }
}

test "empty input returns error" {
  assert(is_err(yaml_parse("")))
}

// --- String tests ---

test "bare string" {
  match yaml_parse("hello") {
    Ok(YStr(s)) => assert(s == "hello"),
    _ => assert(false)
  }
}

test "bare string with spaces" {
  match yaml_parse("hello world") {
    Ok(YStr(s)) => assert(s == "hello world"),
    _ => assert(false)
  }
}

test "double-quoted string" {
  match yaml_parse("\"hello world\"") {
    Ok(YStr(s)) => assert(s == "hello world"),
    _ => assert(false)
  }
}

test "single-quoted string" {
  match yaml_parse("'hello world'") {
    Ok(YStr(s)) => assert(s == "hello world"),
    _ => assert(false)
  }
}

test "double-quoted preserves number as string" {
  match yaml_parse("\"42\"") {
    Ok(YStr(s)) => assert(s == "42"),
    _ => assert(false)
  }
}

test "single-quoted preserves number as string" {
  match yaml_parse("'42'") {
    Ok(YStr(s)) => assert(s == "42"),
    _ => assert(false)
  }
}

test "empty double-quoted string" {
  match yaml_parse("\"\"") {
    Ok(YStr(s)) => assert(s == ""),
    _ => assert(false)
  }
}

test "empty single-quoted string" {
  match yaml_parse("''") {
    Ok(YStr(s)) => assert(s == ""),
    _ => assert(false)
  }
}

// --- Float tests ---

test "parse positive float" {
  match yaml_parse("3.14") {
    Ok(YFloat(f)) => assert(show_fixed(f, 2) == "3.14"),
    _ => assert(false)
  }
}

test "parse negative float" {
  match yaml_parse("-0.5") {
    Ok(YFloat(f)) => assert(show_fixed(f, 1) == "-0.5"),
    _ => assert(false)
  }
}

test "parse float zero" {
  match yaml_parse("0.0") {
    Ok(YFloat(f)) => assert(show_fixed(f, 1) == "0.0"),
    _ => assert(false)
  }
}

test "parse large float" {
  match yaml_parse("5432.01") {
    Ok(YFloat(f)) => assert(show_fixed(f, 2) == "5432.01"),
    _ => assert(false)
  }
}

test "float not confused with int" {
  match yaml_parse("3.14") {
    Ok(YInt(_)) => assert(false),
    Ok(YFloat(_)) => assert(true),
    _ => assert(false)
  }
}

// --- Bool tests ---

test "parse true" {
  match yaml_parse("true") {
    Ok(YBool(b)) => assert(b == true),
    _ => assert(false)
  }
}

test "parse false" {
  match yaml_parse("false") {
    Ok(YBool(b)) => assert(b == false),
    _ => assert(false)
  }
}

test "parse True" {
  match yaml_parse("True") {
    Ok(YBool(b)) => assert(b == true),
    _ => assert(false)
  }
}

test "parse FALSE" {
  match yaml_parse("FALSE") {
    Ok(YBool(b)) => assert(b == false),
    _ => assert(false)
  }
}

// --- Null tests ---

test "parse null" {
  match yaml_parse("null") {
    Ok(YNull) => assert(true),
    _ => assert(false)
  }
}

test "parse Null" {
  match yaml_parse("Null") {
    Ok(YNull) => assert(true),
    _ => assert(false)
  }
}

test "parse tilde as null" {
  match yaml_parse("~") {
    Ok(YNull) => assert(true),
    _ => assert(false)
  }
}

test "quoted true is string" {
  match yaml_parse("\"true\"") {
    Ok(YStr(s)) => assert(s == "true"),
    _ => assert(false)
  }
}

test "quoted null is string" {
  match yaml_parse("'null'") {
    Ok(YStr(s)) => assert(s == "null"),
    _ => assert(false)
  }
}

// --- Map tests ---

test "simple map" {
  let input = "name: my-project\nversion: 1"
  match yaml_parse(input) {
    Ok(doc) => {
      match yaml_get(doc, "name") {
        Some(v) => assert(yaml_str(v) == Some("my-project")),
        _ => assert(false)
      }
      match yaml_get(doc, "version") {
        Some(v) => assert(yaml_int(v) == Some(1)),
        _ => assert(false)
      }
    },
    _ => assert(false)
  }
}

test "map with bool and null" {
  let input = "enabled: true\ndata: null"
  match yaml_parse(input) {
    Ok(doc) => {
      match yaml_get(doc, "enabled") {
        Some(v) => assert(yaml_bool(v) == Some(true)),
        _ => assert(false)
      }
      match yaml_get(doc, "data") {
        Some(YNull) => assert(true),
        _ => assert(false)
      }
    },
    _ => assert(false)
  }
}

test "nested map" {
  let input = "database:\n  host: localhost\n  port: 5432"
  match yaml_parse(input) {
    Ok(doc) => {
      match yaml_get(doc, "database") {
        Some(inner) => {
          match yaml_get(inner, "host") {
            Some(v) => assert(yaml_str(v) == Some("localhost")),
            _ => assert(false)
          }
          match yaml_get(inner, "port") {
            Some(v) => assert(yaml_int(v) == Some(5432)),
            _ => assert(false)
          }
        },
        _ => assert(false)
      }
    },
    _ => assert(false)
  }
}

test "map with comments" {
  let input = "# this is a comment\nname: test\n# another comment\nport: 80"
  match yaml_parse(input) {
    Ok(doc) => {
      match yaml_get(doc, "name") {
        Some(v) => assert(yaml_str(v) == Some("test")),
        _ => assert(false)
      }
      match yaml_get(doc, "port") {
        Some(v) => assert(yaml_int(v) == Some(80)),
        _ => assert(false)
      }
    },
    _ => assert(false)
  }
}

test "map with inline comment" {
  let input = "name: test # inline comment\nport: 80"
  match yaml_parse(input) {
    Ok(doc) => {
      match yaml_get(doc, "name") {
        Some(YStr(s)) => assert(s == "test"),
        _ => assert(false)
      }
    },
    _ => assert(false)
  }
}

test "yaml_get on map" {
  let input = "host: localhost\nport: 5432"
  match yaml_parse(input) {
    Ok(doc) => {
      match yaml_get(doc, "host") {
        Some(v) => assert(yaml_str(v) == Some("localhost")),
        _ => assert(false)
      }
      match yaml_get(doc, "port") {
        Some(v) => assert(yaml_int(v) == Some(5432)),
        _ => assert(false)
      }
      assert(is_none(yaml_get(doc, "missing")))
    },
    _ => assert(false)
  }
}

// --- List tests ---

test "simple list of strings" {
  let input = "- apple\n- banana\n- cherry"
  match yaml_parse(input) {
    Ok(doc) => {
      match yaml_list(doc) {
        Some(items) => {
          assert(length(items) == 3)
          assert(yaml_str(items[0]) == Some("apple"))
          assert(yaml_str(items[1]) == Some("banana"))
          assert(yaml_str(items[2]) == Some("cherry"))
        },
        _ => assert(false)
      }
    },
    _ => assert(false)
  }
}

test "list of integers" {
  let input = "- 1\n- 2\n- 3"
  match yaml_parse(input) {
    Ok(doc) => {
      match yaml_list(doc) {
        Some(items) => {
          assert(length(items) == 3)
          assert(yaml_int(items[0]) == Some(1))
          assert(yaml_int(items[1]) == Some(2))
          assert(yaml_int(items[2]) == Some(3))
        },
        _ => assert(false)
      }
    },
    _ => assert(false)
  }
}

test "list of mixed scalars" {
  let input = "- hello\n- 42\n- true\n- null"
  match yaml_parse(input) {
    Ok(doc) => {
      match yaml_list(doc) {
        Some(items) => {
          assert(length(items) == 4)
          assert(yaml_str(items[0]) == Some("hello"))
          assert(yaml_int(items[1]) == Some(42))
          assert(yaml_bool(items[2]) == Some(true))
        },
        _ => assert(false)
      }
    },
    _ => assert(false)
  }
}

test "single item list" {
  let input = "- only"
  match yaml_parse(input) {
    Ok(doc) => {
      match yaml_list(doc) {
        Some(items) => {
          assert(length(items) == 1)
          assert(yaml_str(items[0]) == Some("only"))
        },
        _ => assert(false)
      }
    },
    _ => assert(false)
  }
}

test "list with comments" {
  let input = "# fruits\n- apple\n# more\n- banana"
  match yaml_parse(input) {
    Ok(doc) => {
      match yaml_list(doc) {
        Some(items) => {
          assert(length(items) == 2)
          assert(yaml_str(items[0]) == Some("apple"))
          assert(yaml_str(items[1]) == Some("banana"))
        },
        _ => assert(false)
      }
    },
    _ => assert(false)
  }
}

test "map with list value" {
  let input = "fruits:\n  - apple\n  - banana"
  match yaml_parse(input) {
    Ok(doc) => {
      match yaml_get(doc, "fruits") {
        Some(v) => {
          match yaml_list(v) {
            Some(items) => {
              assert(length(items) == 2)
              assert(yaml_str(items[0]) == Some("apple"))
              assert(yaml_str(items[1]) == Some("banana"))
            },
            _ => assert(false)
          }
        },
        _ => assert(false)
      }
    },
    _ => assert(false)
  }
}

test "same-indent list under map key" {
  let input = "ignore:\n- foo\n- bar\nname: test"
  match yaml_parse(input) {
    Ok(doc) => {
      match yaml_get(doc, "ignore") {
        Some(v) => {
          match yaml_list(v) {
            Some(items) => {
              assert(length(items) == 2)
              assert(yaml_str(items[0]) == Some("foo"))
              assert(yaml_str(items[1]) == Some("bar"))
            },
            _ => assert(false)
          }
        },
        _ => assert(false)
      }
      match yaml_get(doc, "name") {
        Some(v) => assert(yaml_str(v) == Some("test")),
        _ => assert(false)
      }
    },
    _ => assert(false)
  }
}

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

test "yaml_show bool lowercase" {
  assert(yaml_show(YBool(true)) == "true")
  assert(yaml_show(YBool(false)) == "false")
}

// --- Pipe-friendly API tests ---

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
