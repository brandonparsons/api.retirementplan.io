require 'spec_helper'

describe Finance::RiskToleranceQuestionnaire do

  before(:each) do
    @answers = {
                             age: 45,
                             sex: 1,
                       no_people: 4,
                 real_estate_val: 3,
                   saving_reason: 0,
             investment_timeline: 1,
      investment_timeline_length: 1,
             economy_performance: 0,
                  financial_risk: 1,
                     credit_card: 1,
                         pension: 4,
                     inheritance: 5,
                        bequeath: 1,
                          degree: 3,
                            loan: 1,
             forseeable_expenses: 1,
                         married: 1,
                  emergency_fund: 2,
                       job_title: 2
    } # These are valid
  end

  describe "questionnaire results" do

    it "calculates correct risk tolerances for the default answers" do
      low, high = Finance::RiskToleranceQuestionnaire.process(@answers)
      low.should  be_within(0.01).of(2.61713445)
      high.should be_within(0.01).of(5.2342689)
    end

    it "calculates correct risk tolerances for a separate set of answers" do
      @answers = {
                               age: 45,
                               sex: 1,
                         no_people: 4,
                   real_estate_val: 3,
                     saving_reason: 0,
               investment_timeline: 0,
        investment_timeline_length: 0,
               economy_performance: 0,
                    financial_risk: 1,
                       credit_card: 1,
                           pension: 4,
                       inheritance: 2,
                          bequeath: 1,
                            degree: 2,
                              loan: 1,
               forseeable_expenses: 1,
                           married: 1,
                    emergency_fund: 2,
                         job_title: 2
      }
      low, high = Finance::RiskToleranceQuestionnaire.process(@answers)
      low.should  be_within(0.01).of(1.7447563)
      high.should be_within(0.01).of(2.61060793)
    end

    it "calculates correct risk tolerances for a separate set of answers" do
      @answers = {
                               age: 20,
                               sex: 1,
                         no_people: 4,
                   real_estate_val: 0,
                     saving_reason: 0,
               investment_timeline: 0,
        investment_timeline_length: 1,
               economy_performance: 0,
                    financial_risk: 1,
                       credit_card: 1,
                           pension: 0,
                       inheritance: 0,
                          bequeath: 1,
                            degree: 1,
                              loan: 0,
               forseeable_expenses: 1,
                           married: 1,
                    emergency_fund: 1,
                         job_title: 2
      }
      low, high = Finance::RiskToleranceQuestionnaire.process(@answers)
      low.should  be_within(0.01).of(1.308567225)
      high.should be_within(0.01).of(1.741853211)
    end

    it "correctly handles special case on saving reason / x3006" do
      @answers[:saving_reason] = 1
      low, high = Finance::RiskToleranceQuestionnaire.process(@answers)
      low.should  be_within(0.01).of(1.04685378)
      high.should be_within(0.01).of(1.306933558)
    end

    it "correctly handles special case on economy_performance / x301_1/3" do
      @answers[:economy_performance] = 1
      low, high = Finance::RiskToleranceQuestionnaire.process(@answers)
      low.should  be_within(0.01).of(2.61713445)
      high.should be_within(0.01).of(5.2342689)
    end

    it "correctly handles first special case on job_title / x7401" do
      @answers[:job_title] = 0
      low, high = Finance::RiskToleranceQuestionnaire.process(@answers)
      low.should  be_within(0.01).of(2.61713445)
      high.should be_within(0.01).of(5.2342689)
    end

    it "correctly handles second special case on job_title / x7401" do
      @answers[:job_title] = 1
      low, high = Finance::RiskToleranceQuestionnaire.process(@answers)
      low.should  be_within(0.01).of(2.61713445)
      high.should be_within(0.01).of(5.2342689)
    end


  end

  describe "supplied answers" do

    it "requires all the answers" do
      expect { Finance::RiskToleranceQuestionnaire.process({age: 5}) }.to raise_error
    end

    it 'boots out extra answers' do
      @answers[:extra_answer] = 2
      q = Finance::RiskToleranceQuestionnaire.send :check_supplied_answers, @answers
      q.should_not have_key(:extra_answer)
      q.should have_key(:job_title)
    end

    it "allows integer values for integer_input types" do
      @answers[:loan] = "0"
      q = Finance::RiskToleranceQuestionnaire.send :check_supplied_answers, @answers
      expect(q[:loan]).to eq(0)
    end

    it 'raises error on non-int values for integer_input types' do
      @answers[:loan] = "hello"
      expect { Finance::RiskToleranceQuestionnaire.send :check_supplied_answers, @answers }.to raise_error
    end

    it "allows integers within select range for select types" do
      @answers[:loan] = 1
      q = Finance::RiskToleranceQuestionnaire.send :check_supplied_answers, @answers
      expect(q[:loan]).to eq(1)
    end

    it 'raises error on integers outside select range for select types' do
      @answers[:loan] = 5
      expect { Finance::RiskToleranceQuestionnaire.send :check_supplied_answers, @answers }.to raise_error
    end

    it 'raises error on non-int types for select types' do
      @answers[:loan] = 'booyah'
      expect { Finance::RiskToleranceQuestionnaire.send :check_supplied_answers, @answers }.to raise_error
    end

  end

  specify "::calculate_pratt_arrow_risk_aversion" do
    pending "Needs test!"
    # market_return     = 0.13
    # market_std_dev    = 0.08
    # risk_free_return  = 0.04
    # stock_ratio       = 0.6

    # pratt_arrow = Finance::PrattArrow.calculate_pratt_arrow_risk_aversion market_return, risk_free_return, stock_ratio, market_std_dev
    # expect(pratt_arrow).to be_within(0.01).of(23.43749)
  end

end
