class SecuritySerializer < ActiveModel::Serializer
  attributes :id, :ticker, :asset_class, :asset_type, :mean_return, :std_dev,
    :implied_return

  has_many :etfs
  embed :ids
end
