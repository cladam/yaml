# yaml

A YAML subset parser library for [Hica](https://github.com/cladam/hica). Parses the YAML that real-world config files actually use: maps, lists, scalars, comments, and nesting.

## Installation

Add as a git submodule to your Hica project:

```sh
git submodule add https://github.com/cladam/yaml.git lib/yaml
```

Then import the modules you need:

```hc
import "./lib/yaml/src/yaml_types"
import "./lib/yaml/src/scalar"
import "./lib/yaml/src/parser"
import "./lib/yaml/src/api"
import "./lib/yaml/src/display"
```

## Supported YAML

- **Scalars**: strings (bare, single-quoted, double-quoted), integers, floats, booleans, null
- **Block maps**: `key: value` with indentation nesting
- **Block sequences**: `- item` lists
- **Comments**: `# ignored`
- **Nested structures**: maps in maps, lists in maps, maps in lists
- **Empty collections**: `[]`

## API

### Types

```hc
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

```hc
yaml_parse(input: string) : result<Yaml, string>
```

### Pipe-friendly navigation

Chain operations with `|>` to navigate nested YAML:

```hc
let host = yaml_parse(input)
  |> yaml_ok
  |> at("database")
  |> at("host")
  |> as_str

// host : maybe<string>
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

```hc
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

```hc
yaml_show(y: Yaml) : string        // compact one-line representation
yaml_pretty(y: Yaml, indent: int) : string  // indented multi-line output
```

## Example

```hc
import "./lib/yaml/src/yaml_types"
import "./lib/yaml/src/scalar"
import "./lib/yaml/src/parser"
import "./lib/yaml/src/api"
import "./lib/yaml/src/display"

fun main() {
  let input = read_file("config.yml")
  match input {
    Ok(text) => {
      match yaml_parse(text) {
        Ok(doc) => {
          println(yaml_pretty(doc, 0))

          let name = yaml_parse(text) |> yaml_ok |> at("name") |> as_str
          match name {
            Some(n) => println("Project: {n}"),
            None => println("no name field")
          }
        },
        Err(e) => println("Parse error: {e}")
      }
    },
    Err(e) => println("File error: {e}")
  }
}
```

## Project structure

```
src/
  yaml_types.hc   # Yaml type and BlockResult struct
  scalar.hc       # Scalar value parsing
  parser.hc       # Block parser and yaml_parse entry point
  api.hc          # Accessors and pipe-friendly API
  display.hc      # yaml_show and yaml_pretty
  yaml.hc         # Barrel module (imports all)
  main.hc         # Demo program
tests/
  test_scalars.hc
  test_block_collections.hc
  test_flow_collections.hc
  test_errors.hc
  test_display.hc
  test_api.hc
```

## License

MIT
