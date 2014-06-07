require 'spec_helper'

describe Expense do

  it "is valid from the factory" do
    expect(create(:expense)).to be_valid
    expect(create(:expense, :onetime)).to be_valid
    expect(create(:expense, :added)).to be_valid
  end

  describe "frequency" do
    it "is ok with a valid frequency" do
      e = build_stubbed(:expense, frequency: "annual")
      e.should be_valid
    end

    it "fails validation if not a good frequency" do
      e = build_stubbed(:expense, frequency: 'booyah')
      e.should_not be_valid
    end
  end

  describe "onetime_on" do
    it "is required if frequency is onetime" do
      e = build_stubbed(:expense, frequency: 'onetime')
      e.should_not be_valid
      e.onetime_on = Time.new(2020, 12, 31)
      e.should be_valid
    end
  end

  describe "::formatted_for_user(user_id)" do
    it "creates default expenses if user doesnt have any" do
      # This will break if you dramatically change the default_expenses
      user_id = SecureRandom.uuid
      results = Expense.formatted_for_user(user_id)
      expect(results).not_to be_nil
      expect(results[:available][:weekly].length).to be >= 1
      expect(results[:added][:monthly].length).to be > 1
    end

    it "properly formats if already has expenses" do
      user_id = SecureRandom.uuid
      create(:expense, user_id: user_id)
      create(:expense, :added, frequency: 'monthly', user_id: user_id)

      results = Expense.formatted_for_user(user_id)
      expect(results).not_to be_nil
      expect(results[:available][:weekly].length).to eql(1)
      expect(results[:available][:monthly].length).to eql(0)
      expect(results[:added][:monthly].length).to eql(1)
      expect(results[:added][:annual].length).to eql(0)
    end
  end

  describe "::create_default_expenses_for(user_id)" do
    it "creates a number of expenses, associated with a user" do
      user_id = SecureRandom.uuid

      expect(Expense.count).to eql(0)
      Expense.create_default_expenses_for(user_id)
      expect(Expense.count).to be > (0)
      Expense.all.each do |exp|
        expect(exp.user_id).to eql(user_id)
      end
    end
  end

end
