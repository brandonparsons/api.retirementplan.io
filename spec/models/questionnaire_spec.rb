require 'spec_helper'

def test_model_validity_for_values(model, property, values)
  model.send("#{property}=".to_sym, ( values.first - 1 ) )
  model.should_not be_valid

  values.each do |value|
    model.send("#{property}=".to_sym, value)
    model.should be_valid
  end

  model.send("#{property}=".to_sym, ( values.last + 1) )
  model.should_not be_valid
end

def should_be_valid_zero_or_one(model, property)
  test_model_validity_for_values(model, property, [0, 1])
end

def should_be_valid_zero_to_six(model, property)
  test_model_validity_for_values(model, property, [0, 6])
end

describe Questionnaire do

  describe "Factory" do
    it "is valid from factory - default" do
      u = build(:questionnaire)
      u.should be_valid
    end

    it "is valid from factory - aggressive" do
      u = build(:questionnaire, :aggressive)
      u.should be_valid
    end

    it "has different pratt arrows for conservative and aggressive" do
      conservative  = create(:questionnaire)
      aggressive    = create(:questionnaire, :aggressive)
      conservative.pratt_arrow_low.should_not eql(aggressive.pratt_arrow_low)
      conservative.pratt_arrow_high.should_not eql(aggressive.pratt_arrow_high)
    end
  end

  describe "pratt arrow" do
    it "is blank from factory" do
      u = build(:questionnaire)
      u.pratt_arrow_low.should be_nil
      u.pratt_arrow_high.should be_nil
    end

    it "is calculated on save" do
      u = build(:questionnaire)
      u.save
      u.pratt_arrow_low.should_not be_nil
      u.pratt_arrow_high.should_not be be_nil
    end

    it 'changes if questionnaire values update' do
      u = build(:questionnaire)
      u.save
      low   = u.pratt_arrow_low
      high  = u.pratt_arrow_high

      u.age = 20
      u.no_people = 1
      u.real_estate_val = 6
      u.investment_timeline = 0
      u.investment_timeline_length = 1
      u.economy_performance = 0
      u.financial_risk = 0
      u.pension = 4
      u.inheritance = 4

      u.save
      u.pratt_arrow_low.should_not eql(low)
      u.pratt_arrow_high.should_not eql(high)
    end
  end

  describe "complete?" do
    it "starts as incomplete" do
      b = build(:questionnaire)
      b.complete?.should be_false
    end

    it "swaps to complete after a successful save" do
      b = build(:questionnaire)
      b.save
      b.complete?.should be_true
    end

    it "does not swap to complete after a failed save" do
      b = build(:questionnaire)
      b.age = nil
      b.save
      b.complete?.should be_false
    end
  end

  describe "validations" do
    it "is invalid without user id" do
      b = build(:questionnaire)
      b.user_id = nil
      b.should_not be_valid
    end

    describe "age" do
      it "invalid negative" do
        b = build(:questionnaire)
        b.age = -5
        b.should_not be_valid
      end

      it "invalid large" do
        b = build(:questionnaire)
        b.age = 130
        b.should_not be_valid
      end
    end

    describe "sex" do
      it "is valid 0 or 1" do
        should_be_valid_zero_or_one( build(:questionnaire), "sex" )
      end
    end

    describe "no_people" do
      it "is valid greater than zero" do
        b = build(:questionnaire)
        b.no_people = 0
        b.should_not be_valid
        b.no_people = -1
        b.should_not be_valid
      end
    end

    describe "real_estate_val" do
      it "is valid 0 to 6" do
        should_be_valid_zero_to_six( build(:questionnaire), "real_estate_val" )
      end
    end

    describe "saving_reason" do
      it "is valid 0 or 1" do
        should_be_valid_zero_or_one( build(:questionnaire), "saving_reason" )
      end
    end

    describe "investment_timeline" do
      it "is valid 0 or 1" do
        should_be_valid_zero_or_one( build(:questionnaire), "investment_timeline" )
      end
    end

    describe "investment_timeline_length" do
      it "is valid 0 or 1" do
        should_be_valid_zero_or_one( build(:questionnaire), "investment_timeline_length" )
      end
    end

    describe "economy_performance" do
      it "is valid 0 or 1" do
        should_be_valid_zero_or_one( build(:questionnaire), "economy_performance" )
      end
    end

    describe "financial_risk" do
      it "is valid 0 or 1" do
        should_be_valid_zero_or_one( build(:questionnaire), "financial_risk" )
      end
    end

    describe "credit_card" do
      it "is valid 0 or 1" do
        should_be_valid_zero_or_one( build(:questionnaire), "credit_card" )
      end
    end

    describe "pension" do
      it "is valid 0 to 6" do
        should_be_valid_zero_to_six( build(:questionnaire), "pension" )
      end
    end

    describe "inheritance" do
      it "is valid 0 to 6" do
        should_be_valid_zero_to_six( build(:questionnaire), "inheritance" )
      end
    end

    describe "bequeath" do
      it "is valid 0 or 1" do
        should_be_valid_zero_or_one( build(:questionnaire), "bequeath" )
      end
    end

    describe "degree" do
      it "is valid for values 1 through 5" do
        test_model_validity_for_values( build(:questionnaire), "degree", [1, 2, 3, 4, 5])
      end
    end

    describe "loan" do
      it "is valid 0 or 1" do
        should_be_valid_zero_or_one( build(:questionnaire), "loan" )
      end
    end

    describe "forseeable_expenses" do
      it "is valid 0 or 1" do
        should_be_valid_zero_or_one( build(:questionnaire), "forseeable_expenses" )
      end
    end

    describe "married" do
      it "is valid 0 or 1" do
        should_be_valid_zero_or_one( build(:questionnaire), "married" )
      end
    end

    describe "emergency_fund" do
      it "is valid 0 to 6" do
        should_be_valid_zero_to_six( build(:questionnaire), "emergency_fund" )
      end
    end

    describe "job_title" do
      it "is valid for 0 through 2" do
        test_model_validity_for_values( build(:questionnaire), "job_title", [0, 1, 2])
      end
    end

    describe "investment_experience" do
      it "is valid for values 0 through 3" do
        test_model_validity_for_values( build(:questionnaire), "investment_experience", [0, 1, 2, 3])
      end
    end

  end

end
