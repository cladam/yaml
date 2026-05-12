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
