// yaml.hc — A YAML subset parser for hica
// Supports: scalars, block maps, block sequences, comments, nesting

type Yaml {
  YStr(value: string),
  YInt(value: int),
  YFloat(value: float),
  YBool(value: bool),
  YNull,
  YList(items: list<Yaml>),
  YMap(entries: list<(string, Yaml)>)
}

// --- Accessors ---

pub fun yaml_get(y: Yaml, key: string) : maybe<Yaml> => match y {
  YMap(entries) => entries
    |> find((entry) => entry.0 == key)
    |> map_maybe((entry) => entry.1),
  _ => None
}

pub fun yaml_str(y: Yaml) : maybe<string> => match y {
  YStr(v) => Some(v),
  _ => None
}

pub fun yaml_int(y: Yaml) : maybe<int> => match y {
  YInt(v) => Some(v),
  _ => None
}

pub fun yaml_float(y: Yaml) : maybe<float> => match y {
  YFloat(v) => Some(v),
  _ => None
}

pub fun yaml_bool(y: Yaml) : maybe<bool> => match y {
  YBool(v) => Some(v),
  _ => None
}

pub fun yaml_list(y: Yaml) : maybe<list<Yaml>> => match y {
  YList(items) => Some(items),
  _ => None
}

pub fun yaml_map(y: Yaml) : maybe<list<(string, Yaml)>> => match y {
  YMap(entries) => Some(entries),
  _ => None
}
