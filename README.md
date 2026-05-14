# yaml

A YAML subset parser library for [hica](https://github.com/cladam/hica). Parses the YAML that real-world config files actually use: maps, lists, scalars, comments, and nesting.

## Installation

Add as a git submodule to your hica project:

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

## Examples

See the [examples/](examples/) directory for runnable programs:

- [basic_parsing.hc](examples/basic_parsing.hc): Parse a YAML string and pretty-print it
- [pipe_navigation.hc](examples/pipe_navigation.hc): Navigate nested values, use defaults, inspect structure
- [read_config.hc](examples/read_config.hc): Read and parse a YAML file from disk

Run an example:

```sh
hica run examples/basic_parsing.hc
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
examples/
  basic_parsing.hc
  pipe_navigation.hc
  read_config.hc
  sample.yml
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
