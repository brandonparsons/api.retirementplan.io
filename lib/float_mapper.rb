module FloatMapper
  extend self

  # Rails likes to serialize/deserialize longer decimal values into bigdecimals,
  # which it then serializes into **strings** not **floats**. Can't figure out an
  # easy way to avoid this behaviour.
  def call(map)
    map.reduce({}) do |memo, (key, value)|
      memo[key] = value.to_f
      memo
    end
  end

end
