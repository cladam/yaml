# yaml

A YAML subset parser library for [hica](https://github.com/cladam/hica). Parses the YAML that real-world config files actually use: maps, lists, scalars, comments, and nesting.

## Installation

Add as a git submodule to your hica project:

```sh
git submodule add https://github.com/cladam/yaml.git lib/yaml
```

Then import the library:

```rust
import "./lib/yaml/src/yaml"
```

## Supported YAML

- **Scalars**: strings (bare, single-quoted, double-quoted with escape sequences), integers (decimal, hex `0x`, octal `0o`), floats (decimal, scientific, `.inf`, `.nan`), booleans, null
- **Block maps**: `key: value` with indentation nesting
- **Block sequences**: `- item` lists, compact nested mappings (`- name: foo`)
- **Block scalars**: literal (`|`) and folded (`>`) with chomping (`-`, `+`), explicit indentation indicators (`|2`, `>4`), and empty line preservation
- **Multi-line scalars**: plain scalar line folding, multi-line quoted strings
- **Flow collections**: sequences (`[a, b, c]`), mappings (`{key: val}`), nested, trailing commas
- **Complex keys**: flow sequences/mappings as mapping keys (`? [a, b]`)
- **Comments**: inline (`# ...`), full-line, inside flow collections, between multi-line scalars
- **Document markers**: `---` and `...` stripped automatically
- **Multi-document streams**: `yaml_parse_all` returns all documents
- **Tags**: `!!str`, `!!int`, `!local`, `!<uri>` — stripped during parse, `!!str` coerces to string
- **Anchors & aliases**: `&name` anchors and `*name` references
- **Duplicate keys**: last value wins
- **Tab rejection**: tabs in indentation produce clear errors
- **Nested structures**: maps in maps, lists in maps, maps in lists, flow inside block

## API

### Types

```rust
type Yaml {
  YStr(value: string),
  YInt(value: int),
  YFloat(value: float),
  YBool(value: bool),
  YNull,
  YList(items: list<Yaml>),
  YMap(entries: list<(string, Yaml)>)
}
```

### Parsing

```rust
yaml_parse(input: string) : result<Yaml, string>      // first document
yaml_parse_all(input: string) : result<list<Yaml>, string>  // all documents
```

### Pipe-friendly navigation

Chain operations with `|>` or `.` to navigate nested YAML:

```rust
let host = yaml_parse(input)
  |> yaml_ok
  |> at("database")
  |> at("host")
  |> as_str

// host : maybe<string>
```

Hica supports Uniform Function Call Syntax (UFCS) with a dot-notation, the above can be written like this:

```rust
let host = yaml_parse(input)
  .yaml_ok
  .at("database")
  .at("host")
  .as_str
```

| Function | Signature | Purpose |
|----------|-----------|---------|
| `yaml_ok` | `result<Yaml, string> -> maybe<Yaml>` | Convert parse result to maybe |
| `at` | `maybe<Yaml>, string -> maybe<Yaml>` | Navigate into a map key |
| `nth` | `maybe<Yaml>, int -> maybe<Yaml>` | Index into a list |
| `as_str` | `maybe<Yaml> -> maybe<string>` | Extract string value |
| `as_int` | `maybe<Yaml> -> maybe<int>` | Extract int value |
| `as_float` | `maybe<Yaml> -> maybe<float>` | Extract float value |
| `as_bool` | `maybe<Yaml> -> maybe<bool>` | Extract bool value |
| `as_list` | `maybe<Yaml> -> maybe<list<Yaml>>` | Extract list |
| `as_map` | `maybe<Yaml> -> maybe<list<(string, Yaml)>>` | Extract map entries |

### Defaults

```rust
let port = yaml_parse(input)
  |> yaml_ok
  |> at("database")
  |> at("port")
let p = int_or(port, 5432)
```

| Function | Signature |
|----------|-----------|
| `str_or` | `maybe<Yaml>, string -> string` |
| `int_or` | `maybe<Yaml>, int -> int` |
| `float_or` | `maybe<Yaml>, float -> float` |
| `bool_or` | `maybe<Yaml>, bool -> bool` |

### Inspection

| Function | Signature | Purpose |
|----------|-----------|---------|
| `has_key` | `maybe<Yaml>, string -> bool` | Check if map has key |
| `keys` | `maybe<Yaml> -> list<string>` | Get map keys |
| `yaml_length` | `maybe<Yaml> -> int` | Count list/map entries |

### Direct accessors

For when you already have a `Yaml` value (not wrapped in `maybe`):

| Function | Signature |
|----------|-----------|
| `yaml_get` | `Yaml, string -> maybe<Yaml>` |
| `yaml_str` | `Yaml -> maybe<string>` |
| `yaml_int` | `Yaml -> maybe<int>` |
| `yaml_float` | `Yaml -> maybe<float>` |
| `yaml_bool` | `Yaml -> maybe<bool>` |
| `yaml_list` | `Yaml -> maybe<list<Yaml>>` |
| `yaml_map` | `Yaml -> maybe<list<(string, Yaml)>>` |

### Display

```rust
yaml_show(y: Yaml) : string        // compact one-line representation
yaml_pretty(y: Yaml, indent: int) : string  // indented multi-line output
```

### Serialization

Emit valid YAML from `Yaml` values:

```rust
yaml_emit(y: Yaml) : string       // block-style (human-readable, indented)
yaml_emit_flow(y: Yaml) : string  // flow-style (compact, single-line)
```

Example:

```rust
let data = YMap([("name", YStr("myapp")), ("port", YInt(8080))])
println(yaml_emit(data))
// name: myapp
// port: 8080

println(yaml_emit_flow(data))
// {name: myapp, port: 8080}
```

## Examples

See the [examples/](examples/) directory for runnable programs:

- [basic_parsing.hc](examples/basic_parsing.hc): Parse a YAML string and pretty-print it
- [pipe_navigation.hc](examples/pipe_navigation.hc): Navigate nested values, use defaults, inspect structure
- [read_config.hc](examples/read_config.hc): Read and parse a YAML file from disk
- [maps_and_lists.hc](examples/maps_and_lists.hc): Block maps, nested maps, lists, structure inspection
- [flow_collections.hc](examples/flow_collections.hc): Flow sequences, flow mappings, mixed block+flow
- [showcase.hc](examples/showcase.hc): Full library showcase — parse, navigate, emit

Run an example:

```sh
hica run examples/basic_parsing.hc
```

## Project structure

```sh
src/
  yaml.hc          # Barrel module — import this
  yaml_types.hc    # Yaml type and BlockResult struct
  scalar.hc        # Scalar value parsing (escapes, flow collections)
  parser.hc        # Block parser, block scalars, yaml_parse entry point
  api.hc           # Accessors and pipe-friendly API
  display.hc       # yaml_show, yaml_pretty, yaml_emit, yaml_emit_flow
  main.hc          # Demo program
examples/
  basic_parsing.hc
  pipe_navigation.hc
  read_config.hc
  maps_and_lists.hc
  flow_collections.hc
tests/
  test_scalars.hc
  test_block_collections.hc
  test_block_scalars.hc
  test_flow_collections.hc
  test_escapes_and_compact.hc
  test_numbers_and_dedup.hc
  test_multiline.hc
  test_documents.hc
  test_structure.hc
  test_api.hc
  test_display.hc
  test_emit.hc
  test_errors.hc
```

## License

MIT
