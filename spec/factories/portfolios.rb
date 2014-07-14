FactoryGirl.define do

  sequence(:weights) do |n|
    assets = ["COMMODITIES", "INTL-STOCK", "CDN-STOCK"]

    weight1 = rand(0..300)
    weight2 = rand(0..300)
    weight3 = 1000 - weight1 - weight2

    weights = [weight1, weight2, weight3]

    Hash[assets.zip(weights.map {|el| el/1000.0})]
  end

  factory :portfolio do
    weights
    user_id { SecureRandom.uuid }
  end

end
