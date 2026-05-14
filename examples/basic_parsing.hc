// examples/basic_parsing.hc — Parse a YAML string and print it
import "../src/yaml"

fun main() {
  let input = "name: my-project\nversion: 1\nenabled: true\ntags:\n  - cli\n  - yaml"

  match yaml_parse(input) {
    Ok(doc) => {
      println("Parsed successfully!\n")
      println(yaml_pretty(doc, 0))
    },
    Err(e) => println("Parse error: {e}")
  }
}
