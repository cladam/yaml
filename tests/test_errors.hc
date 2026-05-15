import "../src/yaml"

test "empty input returns error" {
  assert(is_err(yaml_parse("")))
}

test "tab error includes line number" {
  let input = "name: test\n\tport: 80"
  match yaml_parse(input) {
    Err(msg) => assert(contains(msg, "line 2")),
    Ok(_) => assert(false)
  }
}

test "tab error on first line" {
  let input = "\tname: test"
  match yaml_parse(input) {
    Err(msg) => assert(contains(msg, "line 1")),
    Ok(_) => assert(false)
  }
}

test "yaml_parse_file with valid file" {
  match yaml_parse_file("examples/sample.yml") {
    Ok(doc) => assert(is_some(yaml_get(doc, "name"))),
    Err(_) => assert(false)
  }
}

test "yaml_parse_file with missing file" {
  assert(is_err(yaml_parse_file("nonexistent.yml")))
}

// --- BOM handling ---

test "BOM is stripped from input" {
  let bom = char_to_string(chr(65279))
  let input = join([bom, "name: hello"], "")
  match yaml_parse(input) {
    Ok(doc) => {
      let v = yaml_get(doc, "name")
      match v {
        Some(YStr(s)) => assert(s == "hello"),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

// --- Malformed scalar reporting ---

test "unterminated double quote detected" {
  let input = "key: \"hello"
  match yaml_parse(input) {
    Err(msg) => {
      assert(contains(msg, "unterminated"))
      assert(contains(msg, "line 1"))
    },
    Ok(_) => assert(false)
  }
}

test "unterminated single quote detected" {
  let input = "key: 'hello"
  match yaml_parse(input) {
    Err(msg) => {
      assert(contains(msg, "unterminated"))
      assert(contains(msg, "line 1"))
    },
    Ok(_) => assert(false)
  }
}

test "unterminated flow sequence detected" {
  let input = "key: [a, b"
  match yaml_parse(input) {
    Err(msg) => {
      assert(contains(msg, "unterminated"))
      assert(contains(msg, "line 1"))
    },
    Ok(_) => assert(false)
  }
}

test "unterminated flow mapping detected" {
  let input = join(["key: ", "{", "a: 1"], "")
  match yaml_parse(input) {
    Err(msg) => {
      assert(contains(msg, "unterminated"))
      assert(contains(msg, "line 1"))
    },
    Ok(_) => assert(false)
  }
}

test "properly closed quotes are fine" {
  let input = "key: \"hello world\""
  assert(is_ok(yaml_parse(input)))
}

test "multi-line quoted string not flagged" {
  let input = "key: \"hello\n  world\""
  assert(is_ok(yaml_parse(input)))
}