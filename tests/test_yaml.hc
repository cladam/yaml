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
