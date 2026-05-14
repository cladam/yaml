import "../src/yaml"

// --- Multi-document streams ---

test "yaml_parse_all with two documents" {
  let input = "name: first\n---\nname: second"
  match yaml_parse_all(input) {
    Ok(docs) => {
      assert(length(docs) == 2)
    },
    Err(_) => assert(false)
  }
}

test "yaml_parse_all document values" {
  let input = "name: first\n---\nname: second"
  match yaml_parse_all(input) {
    Ok(docs) => {
      assert(length(docs) == 2)
      match docs {
        [d1, d2] => {
          let n1 = Some(d1) |> at("name") |> as_str
          let n2 = Some(d2) |> at("name") |> as_str
          assert(n1 == Some("first"))
          assert(n2 == Some("second"))
        },
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

test "yaml_parse_all with three documents" {
  let input = "a: 1\n---\nb: 2\n---\nc: 3"
  match yaml_parse_all(input) {
    Ok(docs) => assert(length(docs) == 3),
    Err(_) => assert(false)
  }
}

test "yaml_parse_all with end marker" {
  let input = "name: first\n...\nname: second"
  match yaml_parse_all(input) {
    Ok(docs) => assert(length(docs) == 2),
    Err(_) => assert(false)
  }
}

test "yaml_parse_all single document" {
  let input = "name: only"
  match yaml_parse_all(input) {
    Ok(docs) => assert(length(docs) == 1),
    Err(_) => assert(false)
  }
}

test "yaml_parse still returns first document" {
  let input = "name: first\n---\nname: second"
  let doc = yaml_parse(input) |> yaml_ok
  let name = doc |> at("name") |> as_str
  assert(name == Some("first"))
}

test "yaml_parse_all with leading separator" {
  let input = "---\nname: first\n---\nname: second"
  match yaml_parse_all(input) {
    Ok(docs) => assert(length(docs) == 2),
    Err(_) => assert(false)
  }
}

// --- Tab rejection ---

test "tabs in indentation rejected" {
  let input = "name: test\n\tport: 80"
  match yaml_parse(input) {
    Err(msg) => assert(contains(msg, "tab")),
    Ok(_) => assert(false)
  }
}

test "tabs not in indentation accepted" {
  let input = "name: contains\ta\ttab"
  match yaml_parse(input) {
    Ok(doc) => {
      match yaml_get(doc, "name") {
        Some(YStr(s)) => assert(contains(s, "\t")),
        _ => assert(false)
      }
    },
    Err(_) => assert(false)
  }
}

// --- Anchors & Aliases ---

test "anchor on block value" {
  let input = "defaults: &defaults\n  adapter: postgres\n  host: localhost\nproduction:\n  database: prod"
  let doc = yaml_parse(input) |> yaml_ok
  let adapter = doc |> at("defaults") |> at("adapter") |> as_str
  assert(adapter == Some("postgres"))
}

test "simple anchor and alias" {
  let input = "color: &main red\nother: *main"
  let doc = yaml_parse(input) |> yaml_ok
  let color = doc |> at("color") |> as_str
  let other = doc |> at("other") |> as_str
  assert(color == Some("red"))
  assert(other == Some("red"))
}

test "anchor on map value alias resolves" {
  let input = "base: &base\n  x: 1\n  y: 2\ncopy: *base"
  let doc = yaml_parse(input) |> yaml_ok
  let x = doc |> at("copy") |> at("x") |> as_int
  assert(x == Some(1))
}

test "alias in list" {
  let input = "item: &val hello\nitems:\n- *val\n- world"
  let doc = yaml_parse(input) |> yaml_ok
  let first = doc |> at("items") |> nth(0) |> as_str
  let second = doc |> at("items") |> nth(1) |> as_str
  assert(first == Some("hello"))
  assert(second == Some("world"))
}
