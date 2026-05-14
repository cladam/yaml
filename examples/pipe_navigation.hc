// examples/pipe_navigation.hc — Navigate nested YAML with the pipe API
import "../src/yaml_types"
import "../src/scalar"
import "../src/parser"
import "../src/api"

fun main() {
  let input = "database:\n  host: localhost\n  port: 5432\n  replicas:\n    - db1\n    - db2\napp:\n  name: myapp\n  debug: false"

  let doc = yaml_parse(input) |> yaml_ok

  // Navigate to nested values
  let host = doc |> at("database") |> at("host") |> as_str
  match host {
    Some(h) => println("Host: {h}"),
    None => println("no host")
  }

  // Use defaults for missing or optional values
  let port = int_or(doc |> at("database") |> at("port"), 3306)
  println("Port: {show(port)}")

  let timeout = int_or(doc |> at("database") |> at("timeout"), 30)
  println("Timeout (default): {show(timeout)}")

  // Index into lists
  let first_replica = doc |> at("database") |> at("replicas") |> nth(0) |> as_str
  match first_replica {
    Some(r) => println("First replica: {r}"),
    None => println("no replicas")
  }

  // Inspect structure
  let db = doc |> at("database")
  println("DB keys: {show(keys(db))}")
  println("Has port? {show(has_key(db, "port"))}")
  println("Replica count: {show(yaml_length(db |> at("replicas")))}")
}
