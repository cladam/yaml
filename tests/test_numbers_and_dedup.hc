import "../src/yaml"

// --- Hex integers ---

test "parse hex integer" {
  let doc = yaml_parse("val: 0x3A") |> yaml_ok
  let val = doc |> at("val") |> as_int
  assert(val == Some(58))
}

test "parse hex uppercase" {
  let doc = yaml_parse("val: 0xFF") |> yaml_ok
  let val = doc |> at("val") |> as_int
  assert(val == Some(255))
}

test "parse hex zero" {
  let doc = yaml_parse("val: 0x0") |> yaml_ok
  let val = doc |> at("val") |> as_int
  assert(val == Some(0))
}

// --- Octal integers ---

test "parse octal integer" {
  let doc = yaml_parse("val: 0o17") |> yaml_ok
  let val = doc |> at("val") |> as_int
  assert(val == Some(15))
}

test "parse octal 7" {
  let doc = yaml_parse("val: 0o7") |> yaml_ok
  let val = doc |> at("val") |> as_int
  assert(val == Some(7))
}

test "parse octal 755" {
  let doc = yaml_parse("val: 0o755") |> yaml_ok
  let val = doc |> at("val") |> as_int
  assert(val == Some(493))
}

// --- Special floats ---

test "parse .inf" {
  match yaml_parse(".inf") {
    Ok(YFloat(_)) => assert(true),
    _ => assert(false)
  }
}

test "parse -.inf" {
  match yaml_parse("-.inf") {
    Ok(YFloat(_)) => assert(true),
    _ => assert(false)
  }
}

test "parse .nan" {
  match yaml_parse(".nan") {
    Ok(YFloat(_)) => assert(true),
    _ => assert(false)
  }
}

test "parse .Inf case insensitive" {
  match yaml_parse(".Inf") {
    Ok(YFloat(_)) => assert(true),
    _ => assert(false)
  }
}

// --- Scientific notation ---

test "parse scientific float" {
  let doc = yaml_parse("val: 1.2e3") |> yaml_ok
  let val = doc |> at("val") |> as_float
  match val {
    Some(f) => assert(f > 1199.0 && f < 1201.0),
    None => assert(false)
  }
}

test "parse negative scientific float" {
  match yaml_parse("val: -2.5e-1") {
    Ok(YMap(_)) => assert(true),
    _ => assert(false)
  }
}

// --- Duplicate key handling ---

test "duplicate keys last wins" {
  let doc = yaml_parse("name: first\nname: second") |> yaml_ok
  let name = doc |> at("name") |> as_str
  assert(name == Some("second"))
}

test "duplicate keys preserves non-dup order" {
  let doc = yaml_parse("a: 1\nb: 2\na: 3") |> yaml_ok
  let b = doc |> at("b") |> as_int
  let a = doc |> at("a") |> as_int
  assert(b == Some(2))
  assert(a == Some(3))
}

test "no duplicate keys unchanged" {
  let doc = yaml_parse("x: 1\ny: 2\nz: 3") |> yaml_ok
  let x = doc |> at("x") |> as_int
  let z = doc |> at("z") |> as_int
  assert(x == Some(1))
  assert(z == Some(3))
}
