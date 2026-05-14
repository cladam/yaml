import "./yaml_types"
import "./scalar"
import "./parser"
import "./display"

fun main() {
  let content = read_file(".tbdflow.yml")
  match content {
    Ok(text) => {
      match yaml_parse(text) {
        Ok(doc) => {
          println("Parsed .tbdflow.yml successfully!\n")
          println(yaml_pretty(doc, 0))
        },
        Err(e) => println("Parse error: {e}")
      }
    },
    Err(e) => println("File error: {e}")
  }
}
