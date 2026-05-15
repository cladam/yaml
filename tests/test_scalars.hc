import "../src/yaml"

// --- Integer tests ---
// Workaround: Koka 3.2.3 Perceus drops constructors under -O2,
// so we check via accessors/yaml_pretty instead of pattern matching.

test "parse positive integer" {
  let doc = yaml_parse("42") |> yaml_ok
  let r = as_int(doc)
  assert(r == Some(42))
}

test "parse negative integer" {
  let doc = yaml_parse("-7") |> yaml_ok
  let r = as_int(doc)
  assert(r == Some(0 - 7))
}

test "parse zero" {
  let doc = yaml_parse("0") |> yaml_ok
  let r = as_int(doc)
  assert(r == Some(0))
}

test "parse integer with whitespace" {
  let doc = yaml_parse("  99  ") |> yaml_ok
  let r = as_int(doc)
  assert(r == Some(99))
}

test "non-integer falls back to string" {
  let doc = yaml_parse("hello") |> yaml_ok
  let r = as_str(doc)
  assert(r == Some("hello"))
}

// --- String tests ---

test "bare string" {
  let doc = yaml_parse("hello") |> yaml_ok
  let r = as_str(doc)
  assert(r == Some("hello"))
}

test "bare string with spaces" {
  let doc = yaml_parse("hello world") |> yaml_ok
  let r = as_str(doc)
  assert(r == Some("hello world"))
}

test "double-quoted string" {
  let doc = yaml_parse("\"hello world\"") |> yaml_ok
  let r = as_str(doc)
  assert(r == Some("hello world"))
}

test "single-quoted string" {
  let doc = yaml_parse("'hello world'") |> yaml_ok
  let r = as_str(doc)
  assert(r == Some("hello world"))
}

test "double-quoted preserves number as string" {
  let doc = yaml_parse("\"42\"") |> yaml_ok
  let r = as_str(doc)
  assert(r == Some("42"))
}

test "single-quoted preserves number as string" {
  let doc = yaml_parse("'42'") |> yaml_ok
  let r = as_str(doc)
  assert(r == Some("42"))
}

test "empty double-quoted string" {
  let doc = yaml_parse("\"\"") |> yaml_ok
  let r = as_str(doc)
  assert(r == Some(""))
}

test "empty single-quoted string" {
  let doc = yaml_parse("''") |> yaml_ok
  let r = as_str(doc)
  assert(r == Some(""))
}

// --- Float tests ---

test "parse positive float" {
  match yaml_parse("3.14") {
    Ok(d) => assert(contains(yaml_pretty(d, 0), "3.14")),
    Err(_) => assert(false)
  }
}

test "parse negative float" {
  match yaml_parse("-0.5") {
    Ok(d) => assert(contains(yaml_pretty(d, 0), "0.5")),
    Err(_) => assert(false)
  }
}

test "parse float zero" {
  let doc = yaml_parse("0.0") |> yaml_ok
  let r = as_float(doc)
  match r {
    Some(_) => assert(true),
    None => assert(false)
  }
}

test "parse large float" {
  match yaml_parse("5432.01") {
    Ok(d) => assert(contains(yaml_pretty(d, 0), "5432")),
    Err(_) => assert(false)
  }
}

test "float not confused with int" {
  let doc = yaml_parse("3.14") |> yaml_ok
  let r = as_int(doc)
  assert(r == None)
  let f = as_float(doc)
  match f {
    Some(_) => assert(true),
    None => assert(false)
  }
}

// --- Bool tests ---

test "parse true" {
  let doc = yaml_parse("true") |> yaml_ok
  let r = as_bool(doc)
  assert(r == Some(true))
}

test "parse false" {
  let doc = yaml_parse("false") |> yaml_ok
  let r = as_bool(doc)
  assert(r == Some(false))
}

test "parse True" {
  let doc = yaml_parse("True") |> yaml_ok
  let r = as_bool(doc)
  assert(r == Some(true))
}

test "parse FALSE" {
  let doc = yaml_parse("FALSE") |> yaml_ok
  let r = as_bool(doc)
  assert(r == Some(false))
}

// --- Null tests ---

test "parse null" {
  match yaml_parse("null") {
    Ok(d) => assert(contains(yaml_pretty(d, 0), "null")),
    Err(_) => assert(false)
  }
}

test "parse Null" {
  match yaml_parse("Null") {
    Ok(d) => assert(contains(yaml_pretty(d, 0), "null")),
    Err(_) => assert(false)
  }
}

test "parse tilde as null" {
  match yaml_parse("~") {
    Ok(d) => assert(contains(yaml_pretty(d, 0), "null")),
    Err(_) => assert(false)
  }
}

test "quoted true is string" {
  let doc = yaml_parse("\"true\"") |> yaml_ok
  let r = as_str(doc)
  assert(r == Some("true"))
}

test "quoted null is string" {
  let doc = yaml_parse("'null'") |> yaml_ok
  let r = as_str(doc)
  assert(r == Some("null"))
}

// --- Tag stripping ---

test "shorthand tag stripped from map value" {
  let doc = yaml_parse("name: !!str 42") |> yaml_ok
  let r = doc |> at("name") |> as_str
  assert(r == Some("42"))
}

test "shorthand tag stripped int stays int" {
  let doc = yaml_parse("val: !!int 42") |> yaml_ok
  let r = doc |> at("val") |> as_int
  assert(r == Some(42))
}

test "local tag stripped from value" {
  let doc = yaml_parse("val: !custom hello") |> yaml_ok
  let r = doc |> at("val") |> as_str
  assert(r == Some("hello"))
}

test "verbatim tag stripped from value" {
  let doc = yaml_parse("val: !<tag:yaml.org,2002:str> hello") |> yaml_ok
  let r = doc |> at("val") |> as_str
  assert(r == Some("hello"))
}

test "tag stripped from list item" {
  let doc = yaml_parse("- !!str 99\n- !!int 5") |> yaml_ok
  let r = doc |> nth(0) |> as_str
  assert(r == Some("99"))
}

test "tag stripped from bare scalar" {
  let doc = yaml_parse("!!str 42") |> yaml_ok
  let r = as_str(doc)
  assert(r == Some("42"))
}

test "tag only value is null" {
  let doc = yaml_parse("key: !!null") |> yaml_ok
  let r = doc |> at("key") |> as_str
  assert(r == None)
}
