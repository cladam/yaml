import "../src/yaml"

fun test_let_in_if(x: int) : string {
  if x > 0 {
    let msg = "positive"
    msg
  } else {
    let msg = "non-positive"
    msg
  }
}

test "let in if branch" {
  assert(test_let_in_if(5) == "positive")
  assert(test_let_in_if(0) == "non-positive")
}
