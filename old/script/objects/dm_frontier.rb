require 'data_mapper'

class DmEfficientFrontier
  include DataMapper::Resource
  validates_presence_of   :allowable_securities
  validates_uniqueness_of :securities_md5_hash

  property :id,                               Serial
  property :allowable_securities_serialized,  Json
  property :securities_md5_hash,              String, index: true

  has n, :dm_portfolios

  ## CLASS ##

  def self.with_allowable_securities(allowable_securities_array)
    return [] if allowable_securities_array.empty?
    normalized = normalize_allowable_securities(allowable_securities_array)
    md5 = md5_hash(normalized)
    first( securities_md5_hash: md5 )
  end


  ## INSTANCE ##

  def allowable_securities
    allowable_securities_serialized["array"]
  end

  def allowable_securities=(array)
    normalized = self.class.normalize_allowable_securities(array)
    md5 = self.class.md5_hash(normalized)
    self.allowable_securities_serialized = { "array" => normalized }
    self.securities_md5_hash = md5
  end


  private

  def self.normalize_allowable_securities(allowable_securities_array)
    allowable_securities_array.sort
  end

  def self.md5_hash(array)
    Digest::MD5.hexdigest(array.to_json)
  end

end
