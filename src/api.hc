// api.hc — Accessors and pipe-friendly API
import "./yaml_types"

// ============================================================
// Accessors
// ============================================================

pub fun yaml_get(y: Yaml, key: string) : maybe<Yaml> => match y {
  YMap(entries) => entries
    |> find((e) => e.0 == key)
    |> map_maybe((e) => e.1),
  _ => None
}

pub fun yaml_str(y: Yaml) : maybe<string> => match y {
  YStr(v) => Some(v),
  _ => None
}

pub fun yaml_int(y: Yaml) : maybe<int> => match y {
  YInt(v) => Some(v),
  _ => None
}

pub fun yaml_float(y: Yaml) : maybe<float> => match y {
  YFloat(v) => Some(v),
  _ => None
}

pub fun yaml_bool(y: Yaml) : maybe<bool> => match y {
  YBool(v) => Some(v),
  _ => None
}

pub fun yaml_list(y: Yaml) : maybe<list<Yaml>> => match y {
  YList(items) => Some(items),
  _ => None
}

pub fun yaml_map(y: Yaml) : maybe<list<(string, Yaml)>> => match y {
  YMap(entries) => Some(entries),
  _ => None
}

// ============================================================
// Pipe-friendly API
// ============================================================
// Usage: yaml_parse(input) |> yaml_ok |> at("db") |> at("host") |> as_str

pub fun yaml_ok(r: result<Yaml, string>) : maybe<Yaml> => match r {
  Ok(y) => Some(y),
  Err(_) => None
}

pub fun at(m: maybe<Yaml>, key: string) : maybe<Yaml> => match m {
  Some(y) => yaml_get(y, key),
  None => None
}

pub fun nth(m: maybe<Yaml>, index: int) : maybe<Yaml> => match m {
  Some(YList(items)) => list_at(items, index),
  _ => None
}

pub fun list_at(xs: list<Yaml>, i: int) : maybe<Yaml> => match xs {
  [] => None,
  [x, ..rest] => if i == 0 { Some(x) } else { list_at(rest, i - 1) }
}

pub fun as_str(m: maybe<Yaml>) : maybe<string> => match m {
  Some(y) => yaml_str(y),
  None => None
}

pub fun as_int(m: maybe<Yaml>) : maybe<int> => match m {
  Some(y) => yaml_int(y),
  None => None
}

pub fun as_float(m: maybe<Yaml>) : maybe<float> => match m {
  Some(y) => yaml_float(y),
  None => None
}

pub fun as_bool(m: maybe<Yaml>) : maybe<bool> => match m {
  Some(y) => yaml_bool(y),
  None => None
}

pub fun as_list(m: maybe<Yaml>) : maybe<list<Yaml>> => match m {
  Some(y) => yaml_list(y),
  None => None
}

pub fun as_map(m: maybe<Yaml>) : maybe<list<(string, Yaml)>> => match m {
  Some(y) => yaml_map(y),
  None => None
}

pub fun str_or(m: maybe<Yaml>, fallback: string) : string => match as_str(m) {
  Some(v) => v,
  None => fallback
}

pub fun int_or(m: maybe<Yaml>, fallback: int) : int => match as_int(m) {
  Some(v) => v,
  None => fallback
}

pub fun float_or(m: maybe<Yaml>, fallback: float) : float => match as_float(m) {
  Some(v) => v,
  None => fallback
}

pub fun bool_or(m: maybe<Yaml>, fallback: bool) : bool => match as_bool(m) {
  Some(v) => v,
  None => fallback
}

pub fun has_key(m: maybe<Yaml>, key: string) : bool => match m {
  Some(y) => is_some(yaml_get(y, key)),
  None => false
}

pub fun keys(m: maybe<Yaml>) : list<string> => match m {
  Some(YMap(entries)) => map(entries, (e) => e.0),
  _ => []
}

pub fun yaml_length(m: maybe<Yaml>) : int => match m {
  Some(YList(items)) => length(items),
  Some(YMap(entries)) => length(entries),
  _ => 0
}
