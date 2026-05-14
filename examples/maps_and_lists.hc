// examples/maps_and_lists.hc — Working with block maps and nested lists
import "../src/yaml_types"
import "../src/scalar"
import "../src/parser"
import "../src/api"
import "../src/display"

fun main() {
  let content = read_file("examples/maps_and_lists.yml")
    match content {
    Ok(text) => {
      match yaml_parse(text) {
        Ok(doc) => {
            let project = Some(doc) |> at("project")

            // Read scalar values from a map
            println("=== Map Access ===")
            let name = project |> at("name") |> as_str
            match name {
                Some(n) => println("Name: {n}"),
                None => println("no name")
            }
            let ver = int_or(project |> at("version"), 0)
            println("Version: {show(ver)}")

            // Iterate over a list
            println("\n=== List Iteration ===")
            let features = project |> at("features")
            println("Feature count: {show(yaml_length(features))}")
            let f0 = features |> nth(0) |> as_str
            let f1 = features |> nth(1) |> as_str
            let f2 = features |> nth(2) |> as_str
            match f0 {
                Some(v) => println("  - {v}"),
                None => println("  (none)")
            }
            match f1 {
                Some(v) => println("  - {v}"),
                None => println("  (none)")
            }
            match f2 {
                Some(v) => println("  - {v}"),
                None => println("  (none)")
            }

            // Nested map access
            println("\n=== Nested Maps ===")
            let db = project |> at("database")
            let db_host = str_or(db |> at("host"), "unknown")
            let db_port = int_or(db |> at("port"), 3306)
            println("DB: {db_host}:{show(db_port)}")

            // Check structure
            println("\n=== Structure Inspection ===")
            println("Project keys: {show(keys(project))}")
            println("Has database? {show(has_key(project, "database"))}")
            println("Has cache? {show(has_key(project, "cache"))}")

            // Nested list inside nested map
            let r0 = db |> at("replicas") |> nth(0) |> as_str
            match r0 {
                Some(r) => println("First replica: {r}"),
                None => println("no replicas")
            }
        },
        Err(e) => println("Parse error: {e}")
      }
    },
    Err(e) => println("File error: {e}")
  }
}
