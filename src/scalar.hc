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
  else if trimmed == "[]" {
    YList([])
  } else {
    YStr(trimmed)
  }
}
