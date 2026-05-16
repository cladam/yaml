// examples/showcase.hc — Full library showcase: parse, navigate, build, emit
import "../src/yaml"

fun main() {
  // --- Parse a YAML document ---
  let input = "app:\n  name: myservice\n  version: 2.1.0\n  port: 8080\n  debug: false\n  tags:\n    - api\n    - production\ndatabase:\n  host: db.example.com\n  port: 5432\n  pool_size: 10"

  println("=== Parse & Navigate ===\n")

  let doc = yaml_parse(input) |> yaml_ok

  let name = doc |> at("app") |> at("name") |> as_str
  match name {
    Some(n) => println("App name: " + n),
    None => println("no name")
  }

  let port = doc |> at("app") |> at("port") |> as_int
  match port {
    Some(p) => println("App port: " + show(p)),
    None => println("no port")
  }

  let db_host = doc |> at("database") |> at("host") |> as_str
  match db_host {
    Some(h) => println("DB host: " + h),
    None => println("no host")
  }

  // Use defaults for missing values
  let timeout = int_or(doc |> at("app") |> at("timeout"), 30)
  println("Timeout (default 30): " + show(timeout))

  // Inspect structure
  let tag_count = yaml_length(doc |> at("app") |> at("tags"))
  println("Tags: " + show(tag_count))

  // --- Build & Emit YAML ---
  println("\n=== Build & Emit (block style) ===\n")

  let config = YMap([
    ("service", YMap([
      ("name", YStr("worker")),
      ("replicas", YInt(3)),
      ("enabled", YBool(true))
    ])),
    ("env", YList([
      YStr("staging"),
      YStr("production")
    ]))
  ])

  println(yaml_emit(config))

  // --- Flow-style emission ---
  println("\n=== Flow Style ===\n")

  let tags = YList([YStr("v1.0"), YStr("latest")])
  println(yaml_emit_flow(tags))

  let meta = YMap([("author", YStr("team")), ("count", YInt(42))])
  println(yaml_emit_flow(meta))

  // --- Round-trip ---
  println("\n=== Round-trip ===\n")

  let emitted = yaml_emit(config)
  let reparsed = yaml_parse(emitted) |> yaml_ok |> at("service") |> at("name") |> as_str
  match reparsed {
    Some(v) => println("Round-trip service.name: " + v),
    None => println("round-trip failed")
  }
}
