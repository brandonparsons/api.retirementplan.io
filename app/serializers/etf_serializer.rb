class EtfSerializer < ActiveModel::Serializer
  attributes :id, :ticker, :description

  has_one :security
  embed :ids
end
