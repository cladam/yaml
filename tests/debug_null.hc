import "../src/yaml"

fun is_null(m: maybe<Yaml>) : bool => match m {
  Some(YNull) => true,
  _ => false
}

fun check_null(m: maybe<Yaml>) : string => match m {
  Some(YNull) => "YNull",
  Some(YStr(s)) => "YStr:" + s,
  Some(YMap(_)) => "YMap",
  Some(YList(_)) => "YList",
  Some(YInt(_)) => "YInt",
  Some(YFloat(_)) => "YFloat",
  Some(YBool(_)) => "YBool",
  None => "None"
}

test "empty value resolves to null (fixed)" {
  let doc = yaml_parse("name:") |> yaml_ok
  let val = doc |> at("name")
  assert(is_null(val))
}
