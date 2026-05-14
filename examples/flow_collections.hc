// examples/flow_collections.hc — Parse flow sequences and flow mappings
import "../src/yaml_types"
import "../src/scalar"
import "../src/parser"
import "../src/api"
import "../src/display"

fun main() {
  // Flow sequences: inline lists
  let seq_input = "colors: [red, green, blue]\ncounts: [1, 2, 3]"
  let doc = yaml_parse(seq_input) |> yaml_ok

  println("=== Flow Sequences ===")
  let colors = doc |> at("colors")
  println("Color count: {show(yaml_length(colors))}")
  let first = colors |> nth(0) |> as_str
  match first {
    Some(c) => println("First color: {c}"),
    None => println("no first color")
  }
  println("Count: {show(yaml_length(colors))}")

  // Flow mappings: inline maps
  let map_input = join(["server: ", "{", "host: localhost, port: 8080", "}"], "")
  let server = yaml_parse(map_input) |> yaml_ok |> at("server")

  println("\n=== Flow Mappings ===")
  let host = server |> at("host") |> as_str
  let port = server |> at("port") |> as_int
  match host {
    Some(h) => println("Host: {h}"),
    None => println("no host")
  }
  match port {
    Some(p) => println("Port: {show(p)}"),
    None => println("no port")
  }

  // Mixed: flow collections inside block structure
  let mixed = "matrix:\n  - [1, 2, 3]\n  - [4, 5, 6]"
  let mat = yaml_parse(mixed) |> yaml_ok |> at("matrix")
  let row1 = mat |> nth(0)
  let val = row1 |> nth(1) |> as_int
  println("\n=== Mixed Block + Flow ===")
  println("Matrix row count: {show(yaml_length(mat))}")
  match val {
    Some(v) => println("matrix[0][1] = {show(v)}"),
    None => println("could not read value")
  }
}
