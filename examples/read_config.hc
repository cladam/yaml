// examples/read_config.hc — Read and parse a YAML config file
import "../src/yaml"

fun main() {
  let content = read_file("examples/sample.yml")
  match content {
    Ok(text) => {
      match yaml_parse(text) {
        Ok(doc) => {
          println("Config:\n")
          println(yaml_pretty(doc, 0))

          println("\n---")

          let name = yaml_parse(text) |> yaml_ok |> at("name") |> as_str
          match name {
            Some(n) => println("Project: {n}"),
            None => println("no name field")
          }

          let version = yaml_parse(text) |> yaml_ok |> at("version") |> as_str
          match version {
            Some(v) => println("Version: {v}"),
            None => println("no version field")
          }
        },
        Err(e) => println("Parse error: {e}")
      }
    },
    Err(e) => println("File error: {e}")
  }
}
