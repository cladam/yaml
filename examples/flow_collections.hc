// examples/flow_collections.hc — Parse flow sequences and flow mappings
import "../src/yaml"

fun main() {
  // Flow sequences: inline lists
  let content = read_file("examples/colours.yml")
  match content {
    Ok(text) => {
      match yaml_parse(text) {
        Ok(raw) => {
          let doc = Some(raw) |> at("colour")

          println("=== Flow Sequences ===")
          let colors = doc |> at("colours")
          println("Color count: {show(yaml_length(colors))}")
          let first = colors |> nth(0) |> as_str
          match first {
            Some(c) => println("First color: {c}"),
            None => println("no first color")
          }
          let fav = doc |> at("favourite") |> as_str
          match fav {
            Some(f) => println("Favourite: {f}"),
            None => println("no favourite")
          }

          // Flow mappings: inline maps
          let server = Some(raw) |> at("server")

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
          let mat = Some(raw) |> at("matrix")
          let row1 = mat |> nth(0)
          let val = row1 |> nth(1) |> as_int
          println("\n=== Mixed Block + Flow ===")
          println("Matrix row count: {show(yaml_length(mat))}")
          match val {
            Some(v) => println("matrix[0][1] = {show(v)}"),
            None => println("could not read value")
          }
        },
        Err(e) => println("Parse error: {e}")
      }
    },
    Err(e) => println("File error: {e}")
  }
}
