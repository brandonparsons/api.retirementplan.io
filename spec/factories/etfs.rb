FactoryGirl.define do
  factory :etf do
    id { SecureRandom.uuid }

    ticker "XLB"
    description "iShares DEX Long Term Bond ETF"

    security_id { SecureRandom.uuid }

    trait :xlb do
      # Inherits default above
    end

    trait :dbc do
      ticker "DBC"
      description "PowerShares DB Commodity Index"
    end

    trait :gsg do
      ticker "GSG"
      description "iShares S&P GSCI Commodity-Indexed ETF"
    end

    trait :usci do
      ticker "USCI"
      description "United States Commodity Index"
    end

  end
end
