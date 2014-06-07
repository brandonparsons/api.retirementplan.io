FactoryGirl.define do
  factory :security do

    ticker "VDMIX"
    asset_type "bond"
    asset_class "Canadian Long-term Bonds"
    returns [0.01, 0.03, -0.03]
    implied_return 0.007

    trait :vdmix do
      # Inherits default above
    end

    trait :bwx do
      ticker "BWX"
      asset_type "bond"
      asset_class "International Bonds"
      returns [0.01, 0.05, -0.04]
      implied_return 0.011
    end

    trait :eem do
      ticker "EEM"
      asset_type "stock"
      asset_class "Emerging Markets Equities"
      returns [0.11, -0.08, 0.03]
      implied_return 0.12
    end

    trait :naesx do
      ticker "NAESX"
      asset_type "stock"
      asset_class "U.S. Small-cap Equities"
      returns [0.13, -0.18, 0.20]
      implied_return 0.15
    end

  end
end
