class PortfolioSerializer < ActiveModel::Serializer
  attributes :id, :weights, :current_shares, :selected_etfs, :tracking
end
