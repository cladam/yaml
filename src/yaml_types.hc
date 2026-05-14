// types.hc — Core YAML types

pub type Yaml {
  YStr(value: string),
  YInt(value: int),
  YFloat(value: float),
  YBool(value: bool),
  YNull,
  YList(items: list<Yaml>),
  YMap(entries: list<(string, Yaml)>)
}

pub struct BlockResult {
  collected: list<string>,
  remaining: list<string>
}
