import "../src/yaml"

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
