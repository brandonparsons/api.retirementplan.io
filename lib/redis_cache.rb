class RedisCache

  NAMESPACE       = "cache"
  DEFAULT_EXPIRY  = 1.hour

  def self.redis
    $redis
  end

  def self.read(key)
    if serialized = redis.get(namespaced key)
      unserialize(serialized)
    else
      nil
    end
  end

  def self.write(key, val, expires=DEFAULT_EXPIRY)
    redis.multi do
      redis.set    namespaced(key), serialize(val)
      redis.expire namespaced(key), expires
    end
    val
  end

  def self.delete(key)
    redis.del(namespaced key)
    true
  end

  def self.fetch(key, expires=DEFAULT_EXPIRY)
    if serialized = redis.get(namespaced key)
      unserialize(serialized)
    else
      result = yield
      redis.multi do
        redis.set     namespaced(key), serialize(result)
        redis.expire  namespaced(key), expires
      end
      return result
    end
  end

  def self.has_key?(key)
    redis.exists(namespaced key)
  end


  private

  def self.namespaced(key)
    "#{NAMESPACE}-#{key}"
  end

  def self.serialize(value)
    JSON.dump({ 'v' => value })
  end

  def self.unserialize(serialized)
    JSON.parse(serialized)['v']
  end

end
