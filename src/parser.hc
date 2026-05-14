// parser.hc — YAML block parser
import "./yaml_types"
import "./scalar"

// ============================================================
// Line helpers
// ============================================================

pub fun indent_of(line: string) : int =>
  str_length(line) - str_length(trim_start(line))

pub fun make_indent(n: int) : string =>
  if n <= 0 { "" } else { " " + make_indent(n - 1) }

pub fun strip_comment(line: string) : string {
  if starts_with(trim_start(line), "#") { "" }
  else {
    match index_of(line, " #") {
      Some(i) => {
        let before = line[:i]
        let open_b = count(before, "[") + count(before, "{")
        let close_b = count(before, "]") + count(before, "}")
        if open_b == close_b { before }
        else { line }
      },
      None => line
    }
  }
}

pub fun count(s: string, ch: string) : int =>
  length(filter(s.split(""), (c) => c == ch))

pub fun is_doc_marker(line: string) : bool {
  let trimmed = trim(line)
  trimmed == "---" || trimmed == "..."
}

pub fun prepare_lines(input: string) : list<string> {
  split(input, "\n")
    |> map((l) => strip_comment(l))
    |> filter((l) => str_length(trim(l)) > 0)
    |> filter((l) => !is_doc_marker(l))
}

pub fun is_list_line(line: string) : bool =>
  starts_with(trim_start(line), "- ")

pub fun list_item_value(line: string) : string =>
  trim(trim_start(line)[2:])

// ============================================================
// Multi-line scalar helpers
// ============================================================

pub fun is_plain_value(s: string) : bool {
  let t = trim(s)
  str_length(t) > 0
    && !starts_with(t, "\"")
    && !starts_with(t, "'")
    && !starts_with(t, "[")
    && !starts_with(t, "{")
    && !starts_with(t, "&")
    && !starts_with(t, "*")
    && !is_block_scalar_indicator(t)
}

pub fun is_open_quoted(s: string) : bool {
  let t = trim(s)
  if str_length(t) < 2 { false }
  else if starts_with(t, "\"") && !ends_with(t, "\"") { true }
  else if starts_with(t, "'") && !ends_with(t, "'") { true }
  else { false }
}

pub fun collect_quoted(lines: list<string>, base_indent: int, quote: string) : BlockResult {
  match lines {
    [] => BlockResult { collected: [], remaining: [] },
    [line, ..rest] => {
      if indent_of(line) <= base_indent {
        BlockResult { collected: [], remaining: lines }
      } else if ends_with(trim(line), quote) {
        BlockResult { collected: [line], remaining: rest }
      } else {
        let inner = collect_quoted(rest, base_indent, quote)
        BlockResult { collected: [line] + inner.collected, remaining: inner.remaining }
      }
    }
  }
}

pub fun join_multiline(first: string, lines: list<string>) : string {
  let parts = [first] + map(lines, (l) => trim(l))
  join(parts, " ")
}

pub fun block_indent_number(indicator: string) : int {
  let t = trim(indicator)
  let rest = t[1:]
  if str_length(rest) == 0 {
    0
  } else if str_length(rest) == 1 && is_digit_str(rest) {
    match parse_int(rest) { Some(n) => n, None => 0 }
  } else if str_length(rest) == 1 {
    0
  } else if str_length(rest) >= 2 && is_digit_str(rest[:1]) {
    match parse_int(rest[:1]) { Some(n) => n, None => 0 }
  } else if str_length(rest) >= 2 && is_digit_str(rest[1:]) {
    match parse_int(rest[1:]) { Some(n) => n, None => 0 }
  } else {
    0
  }
}

// ============================================================
// Block collection helpers
// ============================================================

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

// ============================================================
// Map & list parsing
// ============================================================

pub fun is_map_line(line: string) : bool {
  let trimmed = trim_start(line)
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

pub fun parse_list_entries(lines: list<string>, base_indent: int) : list<Yaml> {
  match lines {
    [] => [],
    [line, ..rest] => {
      if indent_of(line) == base_indent && is_list_line(line) {
        let val_str = list_item_value(line)
        if is_block_scalar_indicator(val_str) {
          let blk = collect_block(rest, base_indent)
          [block_scalar_join(blk.collected, val_str, base_indent)] + parse_list_entries(blk.remaining, base_indent)
        } else if is_open_quoted(val_str) {
          let quote = val_str[:1]
          let cont = collect_quoted(rest, base_indent, quote)
          if length(cont.collected) > 0 {
            let full = join_multiline(val_str, cont.collected)
            [parse_scalar(full)] + parse_list_entries(cont.remaining, base_indent)
          } else {
            [parse_scalar(val_str)] + parse_list_entries(rest, base_indent)
          }
        } else {
          let blk = collect_block(rest, base_indent)
          let has_block = length(blk.collected) > 0
          let has_val = str_length(val_str) > 0
          if has_block && has_val && is_map_line(val_str) {
            let pad = make_indent(base_indent + 2)
            let sub_lines = [pad + val_str] + blk.collected
            [parse_lines(sub_lines)] + parse_list_entries(blk.remaining, base_indent)
          } else if has_block && has_val {
            let parts = [val_str] + map(blk.collected, (l) => trim(l))
            [YStr(join(parts, " "))] + parse_list_entries(blk.remaining, base_indent)
          } else if has_block {
            [parse_lines(blk.collected)] + parse_list_entries(blk.remaining, base_indent)
          } else if is_map_line(val_str) {
            [YMap([(kv_key(val_str), parse_scalar(kv_val(val_str)))])] + parse_list_entries(rest, base_indent)
          } else {
            [parse_scalar(val_str)] + parse_list_entries(rest, base_indent)
          }
        }
      } else {
        parse_list_entries(rest, base_indent)
      }
    }
  }
}

pub fun is_block_scalar_indicator(s: string) : bool {
  let t = trim(s)
  if str_length(t) == 0 { false }
  else {
    let first = t[:1]
    if first != "|" && first != ">" { false }
    else {
      let rest = t[1:]
      if str_length(rest) == 0 { true }
      else if str_length(rest) == 1 {
        rest == "-" || rest == "+" || is_digit_str(rest)
      } else if str_length(rest) == 2 {
        (is_digit_str(rest[:1]) && (rest[1:] == "-" || rest[1:] == "+"))
        || ((rest[:1] == "-" || rest[:1] == "+") && is_digit_str(rest[1:]))
      } else {
        false
      }
    }
  }
}

pub fun strip_block_indent(lines: list<string>, min_ind: int) : list<string> {
  match lines {
    [] => [],
    [l, ..rest] => {
      let stripped = if str_length(trim(l)) == 0 { "" }
                     else if str_length(l) >= min_ind { l[min_ind:] }
                     else { l }
      [stripped] + strip_block_indent(rest, min_ind)
    }
  }
}

pub fun block_scalar_join(lines: list<string>, indicator: string, parent_indent: int) : Yaml {
  let t = trim(indicator)
  let is_literal = starts_with(t, "|")
  let rest_ind = t[1:]
  let has_strip = contains(rest_ind, "-")
  let has_keep = contains(rest_ind, "+")
  let chomp = if has_strip { "strip" }
              else if has_keep { "keep" }
              else { "clip" }
  let explicit_n = block_indent_number(indicator)
  let min_ind = if explicit_n > 0 {
    parent_indent + explicit_n
  } else {
    match lines {
      [] => 0,
      [first, ..] => indent_of(first)
    }
  }
  let stripped = strip_block_indent(lines, min_ind)
  let body = if is_literal {
    join(stripped, "\n")
  } else {
    fold_lines(stripped)
  }
  let result = if chomp == "strip" { trim_end(body) }
               else if chomp == "keep" { body + "\n" }
               else {
                 let trimmed = trim_end(body)
                 if str_length(trimmed) > 0 { trimmed + "\n" } else { "" }
               }
  YStr(result)
}

pub fun fold_lines(lines: list<string>) : string {
  match lines {
    [] => "",
    [single] => single,
    [line, ..rest] => {
      if str_length(trim(line)) == 0 {
        "\n" + fold_lines(rest)
      } else {
        match rest {
          [next, ..] => {
            if str_length(trim(next)) == 0 {
              line + fold_lines(rest)
            } else {
              line + " " + fold_lines(rest)
            }
          },
          [] => line
        }
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
        let raw_val = kv_val(line)
        let anchor_info = strip_anchor(raw_val)
        let val_anchor = anchor_info.0
        let val_after = anchor_info.1
        let val_str = if str_length(val_anchor) > 0 { val_after } else { raw_val }
        let emit_key = if str_length(val_anchor) > 0 { "__anchor:" + val_anchor + ":" + key } else { key }
        if is_block_scalar_indicator(val_str) {
          let blk = collect_block(rest, base_indent)
          [(emit_key, block_scalar_join(blk.collected, val_str, base_indent))] + parse_map_entries(blk.remaining, base_indent)
        } else if str_length(val_str) > 0 {
          if is_open_quoted(val_str) {
            let quote = val_str[:1]
            let cont = collect_quoted(rest, base_indent, quote)
            if length(cont.collected) > 0 {
              let full = join_multiline(val_str, cont.collected)
              [(emit_key, parse_scalar(full))] + parse_map_entries(cont.remaining, base_indent)
            } else {
              [(emit_key, parse_scalar(val_str))] + parse_map_entries(rest, base_indent)
            }
          } else if is_plain_value(val_str) {
            let cont = collect_block(rest, base_indent)
            if length(cont.collected) > 0 {
              let parts = [val_str] + map(cont.collected, (l) => trim(l))
              [(emit_key, YStr(join(parts, " ")))] + parse_map_entries(cont.remaining, base_indent)
            } else {
              [(emit_key, parse_scalar(val_str))] + parse_map_entries(rest, base_indent)
            }
          } else {
            [(emit_key, parse_scalar(val_str))] + parse_map_entries(rest, base_indent)
          }
        } else {
          let is_next_list = match rest {
            [next_line, ..] => indent_of(next_line) == base_indent && is_list_line(next_line),
            [] => false
          }
          if is_next_list {
            let blk = collect_list_block(rest, base_indent)
            [(emit_key, parse_lines(blk.collected))] + parse_map_entries(blk.remaining, base_indent)
          } else if length(rest) > 0 {
            let blk = collect_block(rest, base_indent)
            [(emit_key, parse_lines(blk.collected))] + parse_map_entries(blk.remaining, base_indent)
          } else {
            [(emit_key, YNull)]
          }
        }
      } else {
        parse_map_entries(rest, base_indent)
      }
    }
  }
}

// ============================================================
// Duplicate key handling (last wins)
// ============================================================

pub fun dedup_entries(entries: list<(string, Yaml)>) : list<(string, Yaml)> {
  match entries {
    [] => [],
    [(k, v), ..rest] => {
      let filtered = filter(rest, (e) => e.0 != k)
      if length(filtered) < length(rest) {
        dedup_entries(rest)
      } else {
        [(k, v)] + dedup_entries(rest)
      }
    }
  }
}

// ============================================================
// Top-level dispatch
// ============================================================

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
        YMap(dedup_entries(parse_map_entries(all_lines, indent_of(first))))
      } else {
        parse_scalar(first)
      }
    }
  }
}

// ============================================================
// Tab rejection
// ============================================================

pub fun line_has_tab_indent(l: string) : bool {
  let ind = indent_of(l)
  if ind == 0 { false }
  else { contains(l[:ind], "\t") }
}

pub fun check_tabs(input: string) : bool {
  let lines = split(input, "\n")
  any(lines, (l) => line_has_tab_indent(l))
}

// ============================================================
// Anchor & alias support
// ============================================================

pub fun strip_anchor(s: string) : (string, string) {
  let t = trim(s)
  if starts_with(t, "&") {
    match index_of(t, " ") {
      Some(i) => (t[1:i], trim(t[i + 1:])),
      None => (t[1:], "")
    }
  } else {
    ("", t)
  }
}

pub fun is_alias(s: string) : bool {
  let t = trim(s)
  starts_with(t, "*") && str_length(t) > 1
}

pub fun alias_name(s: string) : string {
  let t = trim(s)
  t[1:]
}

pub fun resolve_alias(name: string, anchors: list<(string, Yaml)>) : Yaml {
  match find(anchors, (e) => e.0 == name) {
    Some(pair) => pair.1,
    None => YStr("*" + name)
  }
}

pub fun resolve_anchors(y: Yaml, anchors: list<(string, Yaml)>) : (Yaml, list<(string, Yaml)>) {
  match y {
    YMap(entries) => {
      let result = resolve_map_anchors(entries, anchors)
      (YMap(result.0), result.1)
    },
    YList(items) => {
      let result = resolve_list_anchors(items, anchors)
      (YList(result.0), result.1)
    },
    _ => (y, anchors)
  }
}

pub fun resolve_map_anchors(entries: list<(string, Yaml)>, anchors: list<(string, Yaml)>) : (list<(string, Yaml)>, list<(string, Yaml)>) {
  match entries {
    [] => ([], anchors),
    [(k, v), ..rest] => {
      let key_anchor = extract_key_anchor(k)
      let anchor_name = key_anchor.0
      let clean_key = key_anchor.1
      let resolved_val = match v {
        YStr(s) => {
          if is_alias(s) {
            ("", resolve_alias(alias_name(s), anchors))
          } else {
            let val_anchor = strip_anchor(s)
            if str_length(val_anchor.0) > 0 {
              (val_anchor.0, parse_scalar(val_anchor.1))
            } else { ("", v) }
          }
        },
        _ => ("", v)
      }
      let effective_anchor = if str_length(anchor_name) > 0 { anchor_name } else { resolved_val.0 }
      let val_resolved = resolved_val.1
      let inner = resolve_anchors(val_resolved, anchors)
      let final_val = inner.0
      let new_anchors = if str_length(effective_anchor) > 0 {
        inner.1 + [(effective_anchor, final_val)]
      } else { inner.1 }
      let rest_result = resolve_map_anchors(rest, new_anchors)
      ([(clean_key, final_val)] + rest_result.0, rest_result.1)
    }
  }
}

pub fun extract_key_anchor(k: string) : (string, string) {
  if starts_with(k, "__anchor:") {
    let after = k[9:]
    match index_of(after, ":") {
      Some(i) => (after[:i], after[i + 1:]),
      None => ("", k)
    }
  } else {
    ("", k)
  }
}

pub fun resolve_list_anchors(items: list<Yaml>, anchors: list<(string, Yaml)>) : (list<Yaml>, list<(string, Yaml)>) {
  match items {
    [] => ([], anchors),
    [item, ..rest] => {
      let resolved = match item {
        YStr(s) => {
          if is_alias(s) {
            resolve_alias(alias_name(s), anchors)
          } else {
            let val_anchor = strip_anchor(s)
            if str_length(val_anchor.0) > 0 {
              parse_scalar(val_anchor.1)
            } else { item }
          }
        },
        _ => item
      }
      let inner = resolve_anchors(resolved, anchors)
      let rest_result = resolve_list_anchors(rest, inner.1)
      ([inner.0] + rest_result.0, rest_result.1)
    }
  }
}

// ============================================================
// Multi-document streams
// ============================================================

pub fun split_documents(input: string) : list<string> {
  let lines = split(input, "\n")
  split_docs_acc(lines, [], [])
}

pub fun split_docs_acc(lines: list<string>, current: list<string>, docs: list<string>) : list<string> {
  match lines {
    [] => {
      let doc = join(current, "\n")
      if str_length(trim(doc)) > 0 { docs + [doc] } else { docs }
    },
    [line, ..rest] => {
      if trim(line) == "---" {
        let doc = join(current, "\n")
        if str_length(trim(doc)) > 0 {
          split_docs_acc(rest, [], docs + [doc])
        } else {
          split_docs_acc(rest, [], docs)
        }
      } else if trim(line) == "..." {
        let doc = join(current, "\n")
        if str_length(trim(doc)) > 0 {
          split_docs_acc(rest, [], docs + [doc])
        } else {
          split_docs_acc(rest, [], docs)
        }
      } else {
        split_docs_acc(rest, current + [line], docs)
      }
    }
  }
}

pub fun parse_single_doc(input: string) : result<Yaml, string> {
  let ls = prepare_lines(input)
  if length(ls) == 0 {
    Err("empty input")
  } else {
    let parsed = parse_lines(ls)
    let resolved = resolve_anchors(parsed, [])
    Ok(resolved.0)
  }
}

pub fun take_first_doc(lines: list<string>, started: bool) : list<string> {
  match lines {
    [] => [],
    [line, ..rest] => {
      let t = trim(line)
      let is_sep = t == "---" || t == "..."
      if is_sep && started { [] }
      else if is_sep { take_first_doc(rest, true) }
      else { [line] + take_first_doc(rest, true) }
    }
  }
}

// ============================================================
// Public entry point
// ============================================================

pub fun yaml_parse(input: string) : result<Yaml, string> {
  let trimmed = trim(input)
  if str_length(trimmed) == 0 {
    Err("empty input")
  } else if check_tabs(input) {
    Err("tabs are not allowed in YAML indentation")
  } else {
    let raw_lines = split(input, "\n")
    let first_doc = take_first_doc(raw_lines, false)
    let doc_str = join(first_doc, "\n")
    let ls = prepare_lines(doc_str)
    if length(ls) == 0 {
      Err("empty input")
    } else {
      let parsed = parse_lines(ls)
      let resolved = resolve_anchors(parsed, [])
      Ok(resolved.0)
    }
  }
}

pub fun collect_errors(results: list<result<Yaml, string>>) : list<string> {
  match results {
    [] => [],
    [Err(msg), ..rest] => [msg] + collect_errors(rest),
    [_, ..rest] => collect_errors(rest)
  }
}

pub fun collect_values(results: list<result<Yaml, string>>) : list<Yaml> {
  match results {
    [] => [],
    [Ok(v), ..rest] => [v] + collect_values(rest),
    [_, ..rest] => collect_values(rest)
  }
}

pub fun yaml_parse_all(input: string) : result<list<Yaml>, string> {
  let trimmed = trim(input)
  if str_length(trimmed) == 0 {
    Err("empty input")
  } else if check_tabs(input) {
    Err("tabs are not allowed in YAML indentation")
  } else {
    let docs = split_documents(input)
    if length(docs) == 0 {
      Err("empty input")
    } else {
      let results = map(docs, (d) => parse_single_doc(d))
      let errs = collect_errors(results)
      match errs {
        [msg, ..] => Err(msg),
        [] => Ok(collect_values(results))
      }
    }
  }
}
