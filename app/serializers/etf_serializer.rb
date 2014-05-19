class EtfSerializer < ApiSerializer
  attributes :id, :ticker, :description

  has_one :security
  embed :ids #, include: true
end
