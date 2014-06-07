require 'data_mapper'

class DmPortfolio
  include DataMapper::Resource
  validates_presence_of   :weights
  validates_uniqueness_of :weights_md5_hash

  property :id,                 Serial
  property :weights,            Json

  property :weights_md5_hash,   String, index: true

  belongs_to :dm_efficient_frontier, required: false

  ## CLASS ##

  def self.with_weights(weights_hash)
    return [] if weights_hash.empty?
    first( weights_md5_hash: md5_hash(normalize_weights(weights_hash)) )
  end


  ## INSTANCE ##

  def weights=(hash)
    normalized = self.class.normalize_weights(hash)
    self.weights_md5_hash = self.class.md5_hash(normalized)
    super(normalized)
  end


  private

  def self.normalize_weights(hash)
    Hash[hash.sort].inject({}) {|h, (k,v)| h[k.upcase] = v.to_f; h  }
  end

  def self.md5_hash(hash)
    Digest::MD5.hexdigest(hash.to_json)
  end

end # DmPortfolio
