// scalar.hc — Scalar value parsing
import "./yaml_types"

pub fun is_digit_str(c: string) : bool =>
  contains("0123456789", c)

pub fun all_digits(s: string) : bool =>
  str_length(s) > 0 && all(s.split(""), (c) => is_digit_str(c))

pub fun is_float_str(s: string) : bool {
  let body = if starts_with(s, "-") { s[1:] } else { s }
  let parts = split(body, ".")
  match parts {
    [a, b] => all_digits(a) && all_digits(b),
    _ => false
  }
}

pub fun parse_scalar(s: string) : Yaml {
  let trimmed = trim(s)

  if starts_with(trimmed, "\"") && ends_with(trimmed, "\"") && str_length(trimmed) >= 2 {
    YStr(trimmed[1:str_length(trimmed) - 1])
  }
  else if starts_with(trimmed, "'") && ends_with(trimmed, "'") && str_length(trimmed) >= 2 {
    YStr(trimmed[1:str_length(trimmed) - 1])
  }
  else if starts_with(trimmed, "-") && all_digits(trimmed[1:]) {
    match parse_int(trimmed) {
      Some(n) => YInt(n),
      None => YStr(trimmed)
    }
  } else if all_digits(trimmed) {
    match parse_int(trimmed) {
      Some(n) => YInt(n),
      None => YStr(trimmed)
    }
  }
  else if is_float_str(trimmed) {
    match parse_float(trimmed) {
      Some(f) => YFloat(f),
      None => YStr(trimmed)
    }
  }
  else if to_lower(trimmed) == "true" {
    YBool(true)
  } else if to_lower(trimmed) == "false" {
    YBool(false)
  }
  else if to_lower(trimmed) == "null" || trimmed == "~" {
    YNull
  }
  else if starts_with(trimmed, "[") && ends_with(trimmed, "]") {
    parse_flow_sequence(trimmed)
  }
  else if starts_with(trimmed, "{") && ends_with(trimmed, "}") {
    parse_flow_mapping(trimmed)
  } else {
    YStr(trimmed)
  }
}

// ============================================================
// Flow sequence parsing
// ============================================================

pub fun parse_flow_sequence(s: string) : Yaml {
  let inner = trim(s[1:str_length(s) - 1])
  if str_length(inner) == 0 {
    YList([])
  } else {
    let parts = split_flow(inner)
    YList(map(parts, (p) => parse_scalar(trim(p))))
  }
}

// Split a flow collection body on commas, respecting [] and {} nesting

// ============================================================
// Flow mapping parsing
// ============================================================

pub fun parse_flow_mapping(s: string) : Yaml {
  let inner = trim(s[1:str_length(s) - 1])
  if str_length(inner) == 0 {
    YMap([])
  } else {
    let parts = split_flow(inner)
    YMap(map(parts, (p) => parse_flow_kv(trim(p))))
  }
}

pub fun parse_flow_kv(s: string) : (string, Yaml) {
  match index_of(s, ": ") {
    Some(i) => (trim(s[:i]), parse_scalar(trim(s[i + 2:]))),
    None => {
      if ends_with(s, ":") {
        (trim(s[:str_length(s) - 1]), YNull)
      } else {
        (s, YNull)
      }
    }
  }
}

// Split a flow collection body on commas, respecting [] and {} nesting
pub fun split_flow(s: string) : list<string> {
  split_flow_acc(s.split(""), 0, 0, "", [])
}

pub fun split_flow_acc(chars: list<string>, brackets: int, braces: int, current: string, acc: list<string>) : list<string> {
  match chars {
    [] => if str_length(current) > 0 { acc + [current] } else { acc },
    [c, ..rest] => {
      if c == "[" {
        split_flow_acc(rest, brackets + 1, braces, current + c, acc)
      } else if c == "]" {
        split_flow_acc(rest, brackets - 1, braces, current + c, acc)
      } else if c == "{" {
        split_flow_acc(rest, brackets, braces + 1, current + c, acc)
      } else if c == "}" {
        split_flow_acc(rest, brackets, braces - 1, current + c, acc)
      } else if c == "," && brackets == 0 && braces == 0 {
        split_flow_acc(rest, brackets, braces, "", acc + [current])
      } else {
        split_flow_acc(rest, brackets, braces, current + c, acc)
      }
    }
  }
}
