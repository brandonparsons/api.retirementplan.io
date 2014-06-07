require 'spec_helper'

describe RetirementSimulationParameters do

  before(:each) do
    @prefs = build_stubbed(:retirement_simulation_parameters)
  end

  it "should be valid from the factory" do
    @prefs.should be_valid
  end

  describe "::default_for_user" do
    before(:each) do
      @u = build_stubbed(:user)
    end

    it "is a new record" do
      q = create(:questionnaire, user: @u)
      r = RetirementSimulationParameters.default_for_user(@u)
      expect(r.new_record?).to be_true
    end

    it "sets all the standard values correctly" do
      q = create(:questionnaire, user: @u)
      r = RetirementSimulationParameters.default_for_user(@u)

      expect(r.expenses_inflation_index).to eql(100)
      expect(r.current_tax_rate).to eql(35)
      expect(r.salary_increase).to eql(3)
      expect(r.retirement_expenses).to eql(100)
      expect(r.retirement_tax_rate).to eql(35)
      expect(r.income_inflation_index).to eql(0)
      expect(r.expenses_multiplier).to eql(1.6)
    end

    context 'user is male' do
      before(:each) do
        @q = create(:questionnaire, user: @u, sex: 1, age: 55)
        @r = RetirementSimulationParameters.default_for_user(@u)
      end

      it "sets user_is_male correctly" do
        expect(@r.user_is_male).to be_true
      end

      it "sets male_age correctly" do
        expect(@r.male_age).to eql(55)
      end

      it "sets female_age correctly" do
        expect(@r.female_age).to be_nil
      end
    end

    context 'user is female' do
      before(:each) do
        @q = create(:questionnaire, user: @u, sex: 0, age: 55)
        @r = RetirementSimulationParameters.default_for_user(@u)
      end

      it "sets user_is_male correctly" do
        expect(@r.user_is_male).to be_false
      end

      it "sets male_age correctly" do
        expect(@r.male_age).to be_nil
      end

      it "sets female_age correctly" do
        expect(@r.female_age).to eql(55)
      end
    end

    it "sets married correctly if not married" do
      q = create(:questionnaire, user: @u, married: 0)
      r = RetirementSimulationParameters.default_for_user(@u)
      expect(r.married).to be_false
    end

    it "sets married correctly if married" do
      q = create(:questionnaire, user: @u, married: 1)
      r = RetirementSimulationParameters.default_for_user(@u)
      expect(r.married).to be_true
    end
  end

  describe "user_retired attribute" do
    it "should be valid if both are not retired" do
      @prefs.user_retired = false
      @prefs.retirement_age_male = 30
      @prefs.retirement_age_female = 35
      @prefs.valid?
      @prefs.should be_valid
    end

    it "should be valid if both are retired" do
      @prefs.user_retired = true
      @prefs.retirement_age_male = 25
      @prefs.retirement_age_female = 25
      @prefs.should be_valid
    end

    it "should not be valid if both are retired and answer is false" do
      @prefs.user_retired = false
      @prefs.retirement_age_male = 25
      @prefs.retirement_age_female = 25
      @prefs.should_not be_valid
    end

    it "should correctly overwrite retirement ages on retired select" do
      @prefs.user_retired = true
      @prefs.valid?
      @prefs.retirement_age_male.should == @prefs.male_age
      @prefs.retirement_age_female.should == @prefs.female_age
    end
  end

  describe "#both_working_from_start" do
    it "provides the correct answer for two people" do
      # Male: 28
      # Female : 29
      # Male retire : 62
      # Female retire : 32
      @prefs.both_working_from_start.should be_true
      @prefs.retirement_age_female = 28
      @prefs.both_working_from_start.should_not be_true
      @prefs.female_age = 27
      @prefs.both_working_from_start.should be_true
      @prefs.female_age = 35
      @prefs.both_working_from_start.should_not be_true
    end

    it "provides the correct answer when not married" do
      # Should always return false if not married
      @prefs.married = false
      @prefs.both_working_from_start.should_not be_true
    end

    it "clears out fraction_for_single_income if not both_working_from_start" do
      @prefs.married = false
      @prefs.valid? # Need to run before_validation callback
      @prefs.both_working_from_start.should_not be_true
      expect(@prefs.fraction_for_single_income).to be_nil
    end
  end

  describe "#both_retired_from_start" do
    it "returns correct values for two people" do
      # Male: 28
      # Female : 29
      # Male retire : 62
      # Female retire : 32
      @prefs.both_retired_from_start.should_not be_true
      @prefs.retirement_age_male = 27
      @prefs.both_retired_from_start.should_not be_true
      @prefs.retirement_age_female = 29
    end

    it "should return true if user_retired selected" do
      # This should munge the ages in such a way that it returns true
      @prefs.user_retired = true
      @prefs.valid? # Required to call the before_validation logic
      @prefs.both_retired_from_start.should be_true
    end

    it "should clear out various values if both_retired_from_start" do
      @prefs.user_retired = true
      @prefs.retirement_expenses = 55
      @prefs.valid? # Required to call the before_validation logic
      @prefs.both_retired_from_start.should be_true
      expect(@prefs.retirement_expenses).to eql(100)
      expect(@prefs.income).to be_nil
      expect(@prefs.current_tax_rate).to be_nil
      expect(@prefs.fraction_for_single_income).to be_nil
      expect(@prefs.salary_increase).to be_nil
    end

    it "returns correct values for male only" do
      # Male: 28
      # Male retire : 62
      @prefs.married = false
      @prefs.female_age = nil
      @prefs.retirement_age_female = nil
      @prefs.both_retired_from_start.should_not be_true
      @prefs.retirement_age_male = 28
      @prefs.both_retired_from_start.should be_true
    end

    it "returns correct values for female only" do
      # Female : 29
      # Female retire : 32
      @prefs.married = false
      @prefs.user_is_male = false
      @prefs.male_age = nil
      @prefs.retirement_age_male = nil
      @prefs.both_retired_from_start.should_not be_true
      @prefs.retirement_age_female = 29
      @prefs.both_retired_from_start.should be_true
    end

    it "validates a number of other properties if false" do
      @prefs.married = false
      @prefs.user_is_male = false
      @prefs.male_age = nil
      @prefs.retirement_age_male = nil
      @prefs.both_retired_from_start.should_not be_true
      @prefs.should be_valid

      @prefs.retirement_expenses = nil
      @prefs.should_not be_valid
      @prefs.retirement_expenses = 85
      @prefs.should be_valid

      @prefs.current_tax_rate = nil
      @prefs.should_not be_valid
      @prefs.current_tax_rate = 35
      @prefs.should be_valid

      @prefs.salary_increase = nil
      @prefs.should_not be_valid
      @prefs.salary_increase = 3
      @prefs.should be_valid

      @prefs.income = nil
      @prefs.should_not be_valid
    end
  end

  describe "house stuff tests" do
    it "sell house in" do
      @prefs.include_home = true
      @prefs.sell_house_in = nil
      @prefs.should_not be_valid
      @prefs.include_home = false
      @prefs.sell_house_in = nil
      @prefs.should be_valid
    end

    it "new_home_relative_value" do
      @prefs.include_home = true
      @prefs.new_home_relative_value = nil
      @prefs.should_not be_valid
      @prefs.include_home = false
      @prefs.new_home_relative_value = nil
      @prefs.should be_valid
    end

    it "home_value" do
      @prefs.include_home = true
      @prefs.home_value = nil
      @prefs.should_not be_valid
      @prefs.include_home = false
      @prefs.home_value = nil
      @prefs.should be_valid
    end

    it "clears out values on before_validation if required" do
      @prefs.include_home = false
      @prefs.valid?
      expect(@prefs.sell_house_in).to be_nil
      expect(@prefs.new_home_relative_value).to be_nil
      expect(@prefs.home_value).to be_nil
    end
  end

  describe "ages and multiplier tests" do
    it "married" do
      @prefs.married = true
      @prefs.expenses_multiplier = nil
      @prefs.should_not be_valid
    end

    it "not married" do
      @prefs.married = false
      @prefs.expenses_multiplier = nil
      @prefs.should be_valid
    end

    describe "clears out values on before_validation if required" do
      it "should delete age details (female)" do
        @prefs.married = false
        @prefs.user_is_male = true
        @prefs.female_age = 26
        @prefs.valid?
        expect(@prefs.female_age).to be_nil
        expect(@prefs.retirement_age_female).to be_nil
      end

      it "should delete age details (male)" do
        @prefs.married = false
        @prefs.user_is_male = false
        @prefs.male_age = 26
        @prefs.valid?
        expect(@prefs.male_age).to be_nil
        expect(@prefs.retirement_age_male).to be_nil
      end

      it "should delete expense multiplier details" do
        @prefs.married = false
        @prefs.valid?
        expect(@prefs.expenses_multiplier).to be_nil
      end
    end

    describe "both working from start logic" do
      it "should correctly figure out if both are working from start" do
        @prefs.male_age = 25
        @prefs.female_age = 27
        @prefs.retirement_age_male = 62
        @prefs.retirement_age_female = 40
        @prefs.both_working_from_start.should be_true
      end

      it "should correctly figure out if both are not working from start (male)" do
        @prefs.male_age = 25
        @prefs.female_age = 27
        @prefs.retirement_age_male = 25
        @prefs.retirement_age_female = 40
        @prefs.both_working_from_start.should_not be_true
      end

      it "should correctly figure out if both are not working from start (female)" do
        @prefs.male_age = 25
        @prefs.female_age = 27
        @prefs.retirement_age_male = 62
        @prefs.retirement_age_female = 27
        @prefs.both_working_from_start.should_not be_true
      end

      it "should check the fractional single income" do
        @prefs.should be_valid
        @prefs.male_age = 25
        @prefs.female_age = 27
        @prefs.retirement_age_male = 62
        @prefs.retirement_age_female = 40
        @prefs.fraction_for_single_income = nil
        @prefs.should_not be_valid
      end
    end

    describe "retirement ages" do
      it "should correctly validate if married - presence" do
        @prefs.married = true
        @prefs.male_age = 25
        @prefs.female_age = 27
        @prefs.retirement_age_male = nil
        @prefs.retirement_age_female = 58
        @prefs.should_not be_valid
      end

      it "should correctly validate if married - presence 2" do
        @prefs.married = true
        @prefs.male_age = 25
        @prefs.female_age = 27
        @prefs.retirement_age_male = 62
        @prefs.retirement_age_female = nil
        @prefs.should_not be_valid
      end

      it "should not care about other retirement age if not married" do
        @prefs.married = false
        @prefs.user_is_male = true
        @prefs.male_age = 25
        @prefs.female_age = nil
        @prefs.retirement_age_male = 62
        @prefs.retirement_age_female = nil
        @prefs.should be_valid
      end

      it "should not care about other retirement age if not married female" do
        @prefs.married = false
        @prefs.user_is_male = false
        @prefs.male_age = nil
        @prefs.female_age = 25
        @prefs.retirement_age_male = nil
        @prefs.retirement_age_female = 26
        @prefs.should be_valid
      end

      it "should correctly validate if ages dont make sense" do
        @prefs.should be_valid
        @prefs.user_retired = true

        # Before validation should push ages to current
        @prefs.valid?
        expect(@prefs.retirement_age_male).to eql(@prefs.male_age)
        expect(@prefs.retirement_age_female).to eql(@prefs.female_age)

        # Should work with lower ages (will get pushed up anyway)
        @prefs.retirement_age_male = 15
        @prefs.retirement_age_female = 15
        @prefs.should be_valid

        # Have to force back to 15 - before_validation above brings back up to
        # current ages.
        @prefs.retirement_age_male = 15
        @prefs.retirement_age_female = 15
        @prefs.user_retired = false
        @prefs.should_not be_valid
      end

      it "should correctly validate if ages dont make sense (one person only)" do
        @prefs.married = false
        @prefs.female_age = nil
        @prefs.retirement_age_female = nil
        @prefs.user_retired = true
        @prefs.should be_valid

        @prefs.retirement_age_male = 15
        @prefs.user_retired = false
        @prefs.should_not be_valid
      end
    end

    describe "user is male" do
      before(:each) do
        @prefs.user_is_male = true
      end

      it "is not married" do
        @prefs.married = false
        @prefs.female_age = nil
        @prefs.should be_valid
        @prefs.male_age = nil
        @prefs.should_not be_valid
      end

      it "is married" do
        @prefs.married = true
        @prefs.female_age = nil
        @prefs.should_not be_valid
      end

      it "more married" do
        @prefs.married = true
        @prefs.should be_valid
        @prefs.male_age = nil
        @prefs.should_not be_valid
      end
    end

    describe "user is female" do
      before(:each) do
        @prefs.user_is_male = false
      end

      it "is not married" do
        @prefs.married = false
        @prefs.male_age = nil
        @prefs.should be_valid
        @prefs.female_age = nil
        @prefs.should_not be_valid
      end

      it "is married" do
        @prefs.married = true
        @prefs.male_age = nil
        @prefs.should_not be_valid
      end

      it "more married" do
        @prefs.married = true
        @prefs.female_age = nil
        @prefs.should_not be_valid
      end
    end

  end # ages and multiplier tests

end
