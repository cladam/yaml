// display.hc — YAML display, pretty-printing, and serialization
import "./yaml_types"

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

// ============================================================
// Serialization — Block Style
// ============================================================

pub fun needs_quoting(s: string) : bool {
  str_length(s) == 0
    || s == "null" || s == "~"
    || s == "true" || s == "false"
    || s == "True" || s == "False"
    || s == "TRUE" || s == "FALSE"
    || starts_with(s, "- ") || starts_with(s, "? ")
    || contains(s, ": ") || contains(s, " #")
    || starts_with(s, "*") || starts_with(s, "&") || starts_with(s, "!")
    || starts_with(s, "'") || starts_with(s, "\"")
    || starts_with(s, "[") || starts_with(s, "]")
    || ends_with(s, ":")
    || contains(s, "\n")
}

pub fun needs_quoting_full(s: string) : bool =>
  if needs_quoting(s) { true }
  else if starts_with(s, join(["{"], "")) { true }
  else if starts_with(s, join(["}", ""], "")) { true }
  else { false }

pub fun escape_yaml_chars(chars: list<string>) : string {
  match chars {
    [] => "",
    [c, ..rest] => {
      if c == "\"" { "\\\"" + escape_yaml_chars(rest) }
      else if c == "\\" { "\\\\" + escape_yaml_chars(rest) }
      else if c == "\n" { "\\n" + escape_yaml_chars(rest) }
      else if c == "\t" { "\\t" + escape_yaml_chars(rest) }
      else { c + escape_yaml_chars(rest) }
    }
  }
}

pub fun emit_scalar(s: string) : string =>
  if str_length(s) == 0 { "\"\"" }
  else if needs_quoting_full(s) { "\"" + escape_yaml_chars(s.split("")) + "\"" }
  else { s }

pub fun emit_scalar_value(y: Yaml) : string => match y {
  YStr(v) => if str_length(v) == 0 { "\"\"" }
    else if needs_quoting_full(v) { "\"" + escape_yaml_chars(v.split("")) + "\"" }
    else { v },
  YInt(v) => show(v),
  YFloat(v) => show(v),
  YBool(v) => if v { "true" } else { "false" },
  YNull => "null",
  _ => ""
}

pub fun emit_map_entry(pad: string, key: string, val: Yaml, indent: int) : string => match val {
  YMap(_) => pad + emit_scalar(key) + ":\n" + yaml_emit_at(val, indent + 1),
  YList(_) => pad + emit_scalar(key) + ":\n" + yaml_emit_at(val, indent + 1),
  _ => pad + emit_scalar(key) + ": " + emit_scalar_value(val)
}

pub fun emit_list_item(pad: string, item: Yaml, indent: int) : string => match item {
  YMap(_) => pad + "-\n" + yaml_emit_at(item, indent + 1),
  YList(_) => pad + "-\n" + yaml_emit_at(item, indent + 1),
  _ => pad + "- " + emit_scalar_value(item)
}

pub fun yaml_emit_at(y: Yaml, indent: int) : string {
  let pad = make_pad(indent)
  match y {
    YMap(entries) => join(map(entries, (e) => {
      emit_map_entry(pad, e.0, e.1, indent)
    }), "\n"),
    YList(items) => join(map(items, (item) => {
      emit_list_item(pad, item, indent)
    }), "\n"),
    _ => emit_scalar_value(y)
  }
}

pub fun yaml_emit(y: Yaml) : string =>
  yaml_emit_at(y, 0)

// ============================================================
// Serialization — Flow Style
// ============================================================

pub fun emit_flow_value(y: Yaml) : string => match y {
  YStr(v) => emit_scalar(v),
  YInt(v) => show(v),
  YFloat(v) => show(v),
  YBool(v) => if v { "true" } else { "false" },
  YNull => "null",
  YList(items) => emit_flow_list(items),
  YMap(entries) => emit_flow_map(entries)
}

pub fun emit_flow_list(items: list<Yaml>) : string {
  let inner = join(map(items, (item) => emit_flow_value(item)), ", ")
  join(["[", inner, "]"], "")
}

pub fun emit_flow_map(entries: list<(string, Yaml)>) : string {
  let inner = join(map(entries, (e) => {
    emit_scalar(e.0) + ": " + emit_flow_value(e.1)
  }), ", ")
  join(["{", inner, "}"], "")
}

pub fun yaml_emit_flow(y: Yaml) : string =>
  emit_flow_value(y)
