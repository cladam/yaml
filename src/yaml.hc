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

// --- Accessors ---

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

// --- Scalar parsing ---

pub fun is_digit_str(c: string) : bool =>
  contains("0123456789", c)

pub fun all_digits(s: string) : bool =>
  str_length(s) > 0 && all(s.split(""), (c) => is_digit_str(c))

pub fun is_float_str(s: string) : bool {
  // Strip optional leading minus
  let body = if starts_with(s, "-") { s[1:] } else { s }
  let parts = split(body, ".")
  match parts {
    [a, b] => all_digits(a) && all_digits(b),
    _ => false
  }
}

pub fun parse_scalar(s: string) : Yaml {
  let trimmed = trim(s)

  // Double-quoted string
  if starts_with(trimmed, "\"") && ends_with(trimmed, "\"") && str_length(trimmed) >= 2 {
    YStr(trimmed[1:str_length(trimmed) - 1])
  }
  // Single-quoted string
  else if starts_with(trimmed, "'") && ends_with(trimmed, "'") && str_length(trimmed) >= 2 {
    YStr(trimmed[1:str_length(trimmed) - 1])
  }
  // Integer: optional minus, then digits
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
  // Float: digits.digits with optional leading minus
  else if is_float_str(trimmed) {
    match parse_float(trimmed) {
      Some(f) => YFloat(f),
      None => YStr(trimmed)
    }
  }
  // Booleans
  else if to_lower(trimmed) == "true" {
    YBool(true)
  } else if to_lower(trimmed) == "false" {
    YBool(false)
  }
  // Null
  else if to_lower(trimmed) == "null" || trimmed == "~" {
    YNull
  }
  // Inline empty list
  else if trimmed == "[]" {
    YList([])
  } else {
    YStr(trimmed)
  }
}

// --- Line helpers ---

pub fun indent_of(line: string) : int =>
  str_length(line) - str_length(trim_start(line))

pub fun strip_comment(line: string) : string {
  match index_of(line, " #") {
    Some(i) => line[:i],
    None => if starts_with(trim_start(line), "#") { "" } else { line }
  }
}

pub fun prepare_lines(input: string) : list<string> {
  split(input, "\n")
    |> map((l) => strip_comment(l))
    |> filter((l) => str_length(trim(l)) > 0)
}

pub fun is_list_line(line: string) : bool =>
  starts_with(trim_start(line), "- ")

pub fun list_item_value(line: string) : string =>
  trim(trim_start(line)[2:])

pub fun parse_list_entries(lines: list<string>, base_indent: int) : list<Yaml> {
  match lines {
    [] => [],
    [line, ..rest] => {
      if indent_of(line) == base_indent && is_list_line(line) {
        let val_str = list_item_value(line)
        let blk = collect_block(rest, base_indent)
        if length(blk.collected) > 0 && str_length(val_str) > 0 {
          let sub_lines = [trim_start(line)[2:]] + blk.collected
          [parse_lines(sub_lines)] + parse_list_entries(blk.remaining, base_indent)
        } else if length(blk.collected) > 0 {
          [parse_lines(blk.collected)] + parse_list_entries(blk.remaining, base_indent)
        } else {
          [parse_scalar(val_str)] + parse_list_entries(rest, base_indent)
        }
      } else {
        parse_list_entries(rest, base_indent)
      }
    }
  }
}

pub fun is_map_line(line: string) : bool {
  let trimmed = trim_start(line)
  // Must contain ": " or end with ":" — but not start with "- "
  if starts_with(trimmed, "- ") { false }
  else {
    match index_of(trimmed, ": ") {
      Some(_) => true,
      None => ends_with(trimmed, ":")
    }
  }
}

pub fun split_kv(line: string) : (string, string) {
  let trimmed = trim_start(line)
  match index_of(trimmed, ": ") {
    Some(i) => (trimmed[:i], trim(trimmed[i + 2:])),
    None => {
      // key with no inline value (nested block follows)
      if ends_with(trimmed, ":") {
        (trimmed[:str_length(trimmed) - 1], "")
      } else {
        (trimmed, "")
      }
    }
  }
}

pub fun kv_key(line: string) : string => split_kv(line).0
pub fun kv_val(line: string) : string => split_kv(line).1

struct BlockResult {
  collected: list<string>,
  remaining: list<string>
}

// Collect lines indented deeper than base_indent from the front of remaining lines
pub fun collect_block(lines: list<string>, base_indent: int) : BlockResult {
  match lines {
    [] => BlockResult { collected: [], remaining: [] },
    [line, ..rest] => {
      if indent_of(line) > base_indent {
        let inner = collect_block(rest, base_indent)
        BlockResult { collected: [line] + inner.collected, remaining: inner.remaining }
      } else {
        BlockResult { collected: [], remaining: lines }
      }
    }
  }
}

// Collect consecutive list lines at the same indent level
pub fun collect_list_block(lines: list<string>, base_indent: int) : BlockResult {
  match lines {
    [] => BlockResult { collected: [], remaining: [] },
    [line, ..rest] => {
      if indent_of(line) == base_indent && is_list_line(line) {
        let inner = collect_list_block(rest, base_indent)
        BlockResult { collected: [line] + inner.collected, remaining: inner.remaining }
      } else {
        BlockResult { collected: [], remaining: lines }
      }
    }
  }
}

pub fun parse_map_entries(lines: list<string>, base_indent: int) : list<(string, Yaml)> {
  match lines {
    [] => [],
    [line, ..rest] => {
      if indent_of(line) == base_indent && is_map_line(line) {
        let key = kv_key(line)
        let val_str = kv_val(line)
        if str_length(val_str) > 0 {
          [(key, parse_scalar(val_str))] + parse_map_entries(rest, base_indent)
        } else {
          let is_next_list = match rest {
            [next_line, ..] => indent_of(next_line) == base_indent && is_list_line(next_line),
            [] => false
          }
          if is_next_list {
            let blk = collect_list_block(rest, base_indent)
            [(key, parse_lines(blk.collected))] + parse_map_entries(blk.remaining, base_indent)
          } else if length(rest) > 0 {
            let blk = collect_block(rest, base_indent)
            [(key, parse_lines(blk.collected))] + parse_map_entries(blk.remaining, base_indent)
          } else {
            [(key, YNull)]
          }
        }
      } else {
        parse_map_entries(rest, base_indent)
      }
    }
  }
}

pub fun parse_lines(all_lines: list<string>) : Yaml {
  match all_lines {
    [] => YNull,
    [single] => {
      if is_list_line(single) {
        YList([parse_scalar(list_item_value(single))])
      } else if is_map_line(single) {
        YMap([(kv_key(single), parse_scalar(kv_val(single)))])
      } else {
        parse_scalar(single)
      }
    },
    [first, ..] => {
      if is_list_line(first) {
        YList(parse_list_entries(all_lines, indent_of(first)))
      } else if is_map_line(first) {
        YMap(parse_map_entries(all_lines, indent_of(first)))
      } else {
        parse_scalar(first)
      }
    }
  }
}

// --- Display ---

pub fun yaml_show(y: Yaml) : string => match y {
  YStr(v) => v,
  YInt(v) => show(v),
  YFloat(v) => show(v),
  YBool(v) => if v { "true" } else { "false" },
  YNull => "null",
  YList(items) => "[list:" + show(length(items)) + "]",
  YMap(entries) => "[map:" + show(length(entries)) + "]"
}

pub fun make_pad(n: int) : string =>
  if n <= 0 { "" } else { "  " + make_pad(n - 1) }

pub fun show_entry_val(v: Yaml, indent: int) : string => match v {
  YMap(es) => "\n" + yaml_pretty(v, indent + 1),
  YList(is) => "\n" + yaml_pretty(v, indent + 1),
  _ => yaml_show(v)
}

pub fun yaml_pretty(y: Yaml, indent: int) : string {
  let pad = make_pad(indent)
  match y {
    YMap(entries) => join(map(entries, (e) => {
      pad + e.0 + ": " + show_entry_val(e.1, indent)
    }), "\n"),
    YList(items) => join(map(items, (i) => {
      pad + "- " + show_entry_val(i, indent)
    }), "\n"),
    _ => pad + yaml_show(y)
  }
}

// --- Public API ---

pub fun yaml_parse(input: string) : result<Yaml, string> {
  let trimmed = trim(input)
  if str_length(trimmed) == 0 {
    Err("empty input")
  } else {
    let ls = prepare_lines(input)
    if length(ls) == 0 {
      Err("empty input")
    } else {
      Ok(parse_lines(ls))
    }
  }
}
