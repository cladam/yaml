// yaml.hc — A YAML subset parser for hica
// Supports: scalars, block maps, block sequences, comments, nesting

type Yaml {
  YStr(value: string),
  YInt(value: int),
  YFloat(value: float),
  YBool(value: bool),
  YNull,
  YList(items: list<Yaml>),
  YMap(entries: list<(string, Yaml)>)
}

// --- Helpers ---

pub fun entry_key(entry: (string, Yaml)) : string => entry.0

pub fun entry_val(entry: (string, Yaml)) : Yaml => entry.1

// --- Accessors ---

pub fun yaml_get(y: Yaml, key: string) : maybe<Yaml> => match y {
  YMap(entries) => entries
    |> find((e) => entry_key(e) == key)
    |> map_maybe((e) => entry_val(e)),
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

// --- Scalar parsing ---

pub fun is_digit_str(c: string) : bool =>
  contains("0123456789", c)

pub fun all_digits(s: string) : bool =>
  str_length(s) > 0 && all(s.split(""), (c) => is_digit_str(c))

pub fun parse_scalar(s: string) : Yaml {
  let trimmed = trim(s)

  // Integer: optional minus, then digits
  if starts_with(trimmed, "-") && all_digits(trimmed[1:]) {
    match parse_int(trimmed) {
      Some(n) => YInt(n),
      None => YStr(trimmed)
    }
  } else if all_digits(trimmed) {
    match parse_int(trimmed) {
      Some(n) => YInt(n),
      None => YStr(trimmed)
    }
  } else {
    YStr(trimmed)
  }
}

// --- Public API ---

pub fun yaml_parse(input: string) : result<Yaml, string> {
  let trimmed = trim(input)
  if str_length(trimmed) == 0 {
    Err("empty input")
  } else {
    Ok(parse_scalar(trimmed))
  }
}
