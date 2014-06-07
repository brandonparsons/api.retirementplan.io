FactoryGirl.define do

  sequence(:weights) do |n|
    s1 = Security.find_by(ticker: "VDMIX")
    s2 = Security.find_by(ticker: "BWX")
    s3 = Security.find_by(ticker: "EEM")

    s1 = FactoryGirl.create(:security, :vdmix) if s1.nil?
    s2 = FactoryGirl.create(:security, :bwx) if s2.nil?
    s3 = FactoryGirl.create(:security, :eem) if s3.nil?

    securities = [s1, s2, s3]

    weight1 = rand(0..300)
    weight2 = rand(0..300)
    weight3 = 1000 - weight1 - weight2

    weights = [weight1, weight2, weight3]

    Hash[securities.map(&:ticker).zip(weights.map {|el| el/1000.0})]
  end

  factory :portfolio do
    weights
    user_id { SecureRandom.uuid }
  end

end
