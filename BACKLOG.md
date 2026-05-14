# YAML Parser Backlog

Status tracking against YAML 1.2.2 spec (https://yaml.org/spec/1.2.2/).
This library targets a practical subset — not full spec compliance.

## Legend

- [x] Implemented
- [ ] Not started
- [-] Partial

---

## Data Types (Ch. 10 — Core Schema)

- [x] Strings (plain scalars)
- [x] Integers (base 10, with sign)
- [ ] Integers (octal `0o7`, hex `0x3A`)
- [x] Floats (decimal, with sign)
- [ ] Floats (scientific notation `1.2e3`, `.inf`, `-.inf`, `.nan`)
- [x] Booleans (`true`/`false`, case-insensitive)
- [x] Null (`null`, `~`)
- [x] Null (empty value resolves to null)

## Scalars (Ch. 7.3, 8.1)

- [x] Plain (unquoted) scalars
- [x] Double-quoted scalars (parsed, with escape sequence processing)
- [x] Single-quoted scalars (parsed, with `''` escape handling)
- [ ] Literal block scalars (`|`)
- [ ] Folded block scalars (`>`)
- [ ] Block chomping indicators (`-`, `+`)
- [ ] Block indentation indicators
- [ ] Multi-line plain scalars (line folding)
- [ ] Multi-line quoted scalars

## Collections — Block Style (Ch. 8.2)

- [x] Block mappings (key: value)
- [x] Block sequences (`- item`)
- [x] Nested mappings (indentation-based)
- [x] Nested sequences
- [x] Sequences under map keys (same-indent and indented)
- [x] Mappings inside sequences
- [x] Compact nested mappings (after `-`)
- [ ] Explicit mapping keys (`? key`)
- [ ] Complex mapping keys (sequences/mappings as keys)

## Collections — Flow Style (Ch. 7.4)

- [x] Empty flow sequence (`[]`)
- [x] Flow sequences (`[a, b, c]`)
- [x] Flow mappings (`{key: val}`)
- [x] Nested flow collections
- [x] Flow collections inside block collections
- [x] Trailing commas in flow collections

## Comments (Ch. 6.6)

- [x] Inline comments (`key: val # comment`)
- [x] Full-line comments (`# comment`)
- [ ] Comments in flow collections
- [ ] Comments between multi-line scalars

## Structure (Ch. 6, 9)

- [x] Document markers (`---`, `...`)
- [ ] Multi-document streams
- [ ] Directives (`%YAML`, `%TAG`)
- [ ] Byte order mark handling

## Node Properties (Ch. 6.9)

- [ ] Anchors (`&name`)
- [ ] Aliases (`*name`)
- [ ] Tags (`!!str`, `!!int`, `!local`, etc.)
- [ ] Verbatim tags (`!<uri>`)

## String Features

- [x] Escape sequences in double-quoted strings (`\n`, `\t`, `\\`, `\"`, `\x`, `\u`, `\U`)
- [x] Single-quote escaping (`''` → `'`)
- [ ] Line folding in flow scalars
- [ ] Preserved newlines in literal blocks
- [ ] Folded newlines in folded blocks

## Whitespace & Indentation (Ch. 6.1–6.5)

- [x] Space-based indentation detection
- [ ] Tab rejection in indentation (tabs currently not handled)
- [ ] Empty line handling inside scalars

## Error Handling

- [x] Empty input detection
- [ ] Indentation error reporting
- [ ] Duplicate key detection
- [ ] Malformed scalar reporting
- [ ] Line number in error messages

## API

- [x] `yaml_parse(input) : result<Yaml, string>`
- [x] Direct accessors: `yaml_get`, `yaml_str`, `yaml_int`, `yaml_float`, `yaml_bool`, `yaml_list`, `yaml_map`
- [x] Pipe-friendly: `yaml_ok`, `at`, `nth`, `as_str`, `as_int`, `as_float`, `as_bool`, `as_list`, `as_map`
- [x] Defaults: `str_or`, `int_or`, `float_or`, `bool_or`
- [x] Inspection: `has_key`, `keys`, `yaml_length`
- [x] Display: `yaml_show`, `yaml_pretty`
- [ ] Serialization (emit/dump YAML from data)
- [ ] `yaml_parse_file(path)` convenience

## Tests

- [x] 52 tests passing (28 scalar + 6 map + 7 list + 2 misc + 9 pipe API)

---

## Priority for tbdflow

Features needed to parse `.tbdflow.yml` — **all done**:

- [x] Block mappings with string/int/bool values
- [x] Nested maps
- [x] Lists under map keys
- [x] Comments
- [x] Pipe-friendly navigation API

Next priorities for general-purpose use:

1. Flow sequences `[a, b, c]`
2. Flow mappings `{key: val}`
3. Multi-line strings (literal `|` and folded `>`)
4. Escape sequences in quoted strings
5. Anchors & aliases
6. Document markers (`---`/`...`)
