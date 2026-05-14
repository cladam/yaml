// display.hc — YAML display and pretty-printing
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
