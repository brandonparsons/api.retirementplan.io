class PortfolioSerializer < ActiveModel::Serializer
  attributes :id, :weights, :current_shares
end
