module Finance
  module RiskToleranceQuestionnaire

    extend self

    def process(answers)
      validated_answers = check_supplied_answers(answers)

      stock_ratio_low, stock_ratio_high = calculate_optimal_bucket(validated_answers)

      pratt_arrow_high = calculate_pratt_arrow_risk_aversion(STUDY_FULLSTOCK_RETURN, STUDY_NOSTOCK_RETURN, stock_ratio_low, STUDY_FULLSTOCK_STDDEV)
      pratt_arrow_low = calculate_pratt_arrow_risk_aversion(STUDY_FULLSTOCK_RETURN, STUDY_NOSTOCK_RETURN, stock_ratio_high, STUDY_FULLSTOCK_STDDEV)

      return pratt_arrow_low, pratt_arrow_high
    end

    def questions_for_form
      questions
    end


    protected

    def calculate_pratt_arrow_risk_aversion(market_return, risk_free_return, stock_ratio, market_std_dev)
      pratt_arrow_risk_aversion = ( market_return - risk_free_return ) / stock_ratio  / ( market_std_dev ** 2 )
      return pratt_arrow_risk_aversion
    end

    def check_supplied_answers(answers)
      # - Only allow answers that have keys matching the 'questions' hash
      # - Should have an answer for all keys in the 'questions' hash
      # - All answers should fall within acceptable limits (e.g. can't select 2 for
      # a set of select options where 0 & 1 are only answers)

      questions     = self.questions
      question_keys = questions.keys

      filtered = answers.slice(*question_keys)
      raise "Missing answers to at least one question" unless filtered.length == question_keys.length

      tested = {}
      filtered.each_pair do |question_key, response|
        if questions[question_key][:type] == :integer_input
          tested[question_key] = convert_to_integer_if_required(response)
        elsif questions[question_key][:type] == :select
          integerized_response = convert_to_integer_if_required(response)
          unless questions[question_key][:answer_options].include?(integerized_response)
            raise "Invalid response for #{question_key}"
          end
          tested[question_key] = integerized_response
        else
          raise "Invalid question type" # Should not get here - controlled by us
        end
      end

      return tested
    end

    def convert_to_integer_if_required(value)
      value.is_a?(Integer) ? value : Integer(value, 10) # Will raise if invalid value
    end


    def calculate_optimal_bucket(answers)
      # Determines optimal portfolio stock percentage (based on return profile of
      # portfolios in dissertation) by applying answers to coefficient matrix and
      # calculating the most probable answer based on regression.
      # Returns high and low stock ratios

      values          = apply_answers_to_coefficients(answers)
      vertical_arrays = collect_vertical_results(values)
      probabilities   = calculate_probabilities(vertical_arrays)
      optimal_bucket  = probabilities.index(probabilities.max)

      case optimal_bucket
      when 0
        stock_ratio_high = 0.399
      when 1
        stock_ratio_high = 0.599
      when 2
        stock_ratio_high = 0.799
      when 3
        stock_ratio_high = 1.000
      else
        raise "Invalid return index" # Should not get here.
      end

      stock_ratio_low = stock_ratio_high - 0.199

      return stock_ratio_low, stock_ratio_high
    end

    def apply_answers_to_coefficients(answers)
      # Applies the supplied answers to the coefficient matrix.

      questions     = self.questions
      coefficients  = self.coefficients

      coefficients_applied = {}

      answers.each_pair do |question_key, response| # (:saving_reason, 1)
        question_info = questions[question_key]
        coefficient   = question_info[:index]

        case question_info[:strategy]
        when :straight_multiplication
          coefficients_applied[coefficient] = coefficients[coefficient].map do |coeff_val|
            response * coeff_val
          end
        when :custom
          case coefficient
          when :x3006
            case response
            when 0
              coefficients_applied[:x3006_1] = coefficients[:x3006_1]
              coefficients_applied[:x3006_5] = coefficients[:x3006_5].map {|val| 0}
            when 1
              coefficients_applied[:x3006_1] = coefficients[:x3006_1].map {|val| 0}
              coefficients_applied[:x3006_5] = coefficients[:x3006_5]
            end
          when :x301
            case response
            when 0
              coefficients_applied[:x301_1] = coefficients[:x301_1]
              coefficients_applied[:x303_3] = coefficients[:x303_3].map {|val| 0}
            when 1
              coefficients_applied[:x301_1] = coefficients[:x301_1].map {|val| 0}
              coefficients_applied[:x303_3] = coefficients[:x303_3]
            end
          when :x7401
            case response
            when 0
              coefficients_applied[:x7401_1] = coefficients[:x7401_1]
              coefficients_applied[:x7401_2] = coefficients[:x7401_2].map {|val| 0}
              coefficients_applied[:x7401_5] = coefficients[:x7401_5].map {|val| 0}
            when 1
              coefficients_applied[:x7401_1] = coefficients[:x7401_1].map {|val| 0}
              coefficients_applied[:x7401_2] = coefficients[:x7401_2]
              coefficients_applied[:x7401_5] = coefficients[:x7401_5].map {|val| 0}
            when 2
              coefficients_applied[:x7401_1] = coefficients[:x7401_1].map {|val| 0}
              coefficients_applied[:x7401_2] = coefficients[:x7401_2].map {|val| 0}
              coefficients_applied[:x7401_5] = coefficients[:x7401_5]
            end
          else
            raise "No strategy for this index" # Should not get here.
          end

        else
          raise "Invalid strategy" # Should not get here
        end
      end

      return coefficients_applied
    end

    def collect_vertical_results(values_hash)
      # Coefficient hash/matrix is sorted by coefficient (e.g. x3006). To gather
      # values for Y1 vs Y2 etc., we need to gather the vertical columns.

      col1 = []
      col2 = []
      col3 = []
      col4 = []

      values_hash.each_pair do |coefficient_index, coefficient_value_array|
        col1 << coefficient_value_array[0]
        col2 << coefficient_value_array[1]
        col3 << coefficient_value_array[2]
        col4 << coefficient_value_array[3]
      end

      return [col1, col2, col3, col4]
    end

    def calculate_probabilities(vertical_arrays)
      # Input is four vertical arrays containing data for P(Y1), P(Y2)....
      # Probability for each option is calculated by summing the calculated values
      # for each option (along with the constant value), exp(sum), then determine
      # the fraction that column's exp(sum) is of all four exp(sum)'s

      constant_values = self.coefficients[:constant]

      summed_and_expd = []

      vertical_arrays.each_with_index do |values, index|
        constant = constant_values[index]
        sum = values.inject(constant) { |sum, n| sum + n }
        expd = Math.exp(sum)
        summed_and_expd << expd
      end

      total = summed_and_expd.inject { |sum, n| sum + n }
      return summed_and_expd.map { |val| val/total }
    end


    ## Not using these right now. The 0.392971 correlation value was backcalculated
    ## by you using the stats in the dissertation.
    # bucket_low_return   = stock_ratio_low * STUDY_FULLSTOCK_RETURN + (1-stock_ratio_low) * STUDY_NOSTOCK_RETURN
    # bucket_low_stddev   = Math.sqrt (stock_ratio_low**2 * STUDY_FULLSTOCK_STDDEV**2 + (1-stock_ratio_low)**2 * STUDY_NOSTOCK_STDDEV**2 + 2 * stock_ratio_low * (1-stock_ratio_low) * STUDY_FULLSTOCK_STDDEV * STUDY_NOSTOCK_STDDEV * 0.392971)
    # bucket_high_return  = stock_ratio_high * STUDY_FULLSTOCK_RETURN + (1-stock_ratio_high) * STUDY_NOSTOCK_RETURN
    # bucket_high_stddev  = Math.sqrt (stock_ratio_high**2 * STUDY_FULLSTOCK_STDDEV**2 + (1-stock_ratio_high)**2 * STUDY_NOSTOCK_STDDEV**2 + 2 * stock_ratio_high * (1-stock_ratio_high) * STUDY_FULLSTOCK_STDDEV * STUDY_NOSTOCK_STDDEV * 0.392971)


    #####################
    # Dissertation Data #
    #####################

    ## Determination of Risk Aversion and Moment-Preferences: A Comparison of Econometric models
    ## Dissertation #2606 - Fabian Wenner
    ## Difo-Druck GmbH, Bamberg 2002

    STUDY_FULLSTOCK_RETURN  = 0.081
    STUDY_FULLSTOCK_STDDEV  = 0.188
    STUDY_NOSTOCK_RETURN    = 0.044
    STUDY_NOSTOCK_STDDEV    = 0.035


    ### The questions and answers are hardcoded into the Ember form!
    def questions
      @questions ||= {

        sex: {
          index: :x8021,
          strategy: :straight_multiplication,
          question: "You are:",
          type: :select,
          answer_options: [0, 1],
          select_options: [
            [0, 'Female'],
            [1, 'Male']
          ]
        },

        age: {
          index: :x8022,
          strategy: :straight_multiplication,
          question: "What is your age?",
          type: :integer_input,
          min: 1,
          max: 119
        },

        married: {
          index: :x7372,
          strategy: :straight_multiplication,
          question: "Are you married?",
          type: :select,
          answer_options: [0, 1],
          select_options: [
            [0, 'No'],
            [1, 'Yes']
          ]
        },

        no_people: {
          index: :x101,
          strategy: :straight_multiplication,
          question: "Number of people in your household?",
          type: :integer_input,
          min: 1
        },

        real_estate_val: {
          index: :x1706,
          strategy: :straight_multiplication,
          question: "How much is your real estate property worth if sold today?",
          type: :select,
          answer_options: [0, 1, 2, 3, 4, 5, 6],
          select_options: [
            [0, "$0"],
            [1, "$1 to $10,000"],
            [2, "$10,000 to $50,000"],
            [3, "$50,000 to $100,000"],
            [4, "$100,000 to $500,000"],
            [5, "$500,000 to $1,000,000"],
            [6, "over $1,000,000"]
          ]
        },

        saving_reason: {
          index: :x3006,
          strategy: :custom,
          question: "What would you describe as your most important reason for saving?",
          type: :select,
          answer_options: [0, 1],
          select_options: [
            [0, 'Liquidity and consumption'],
            [1, 'Education and family']
          ]
          ### MAPPING:
          # Liquidity and consumption? (0) (3006_1 == 1, 3006_5 == 0)
          # Education and family? (1) (3006_1 == 0, 3006_5 == 1)
        },

        investment_timeline: {
          index: :x3008_1,
          strategy: :straight_multiplication,
          question: "In planning your saving and spending, are the next few months most important for you?",
          type: :select,
          answer_options: [0, 1],
          select_options: [
            [0, 'No'],
            [1, 'Yes']
          ]
        },

        investment_timeline_length: {
          index: :x3008_45,
          strategy: :straight_multiplication,
          question: "In planning your saving and spending, do you have longer than 5 years before needing the majority of your funds?",
          type: :select,
          answer_options: [0, 1],
          select_options: [
            [0, 'No'],
            [1, 'Yes']
          ]
        },

        economy_performance: {
          index: :x301,
          strategy: :custom,
          question: "Do you expect the economy to perform better in the next 5 years than it has over the past 5?",
          type: :select,
          answer_options: [0, 1],
          select_options: [
            [0, 'Better'],
            [1, 'Worse']
          ]
          ### MAPPING:
          # Better? (x301_1 == 1, x301_3 == 0)
          # Worse? (x301_1 == 0, x301_3 == 1)
        },

        financial_risk: {
          index: :x3014,
          strategy: :straight_multiplication,
          question: "You are comfortable taking financial risks with your savings.",
          type: :select,
          answer_options: [0, 1],
          select_options: [
            [0, 'True'],
            [1, 'False']
          ]
        },

        credit_card: {
          index: :x432,
          strategy: :straight_multiplication,
          question: "Do you always pay off the full balance of your credit card account each month?",
          type: :select,
          answer_options: [0, 1],
          select_options: [
            [0, 'No'],
            [1, 'Yes']
          ]
        },

        pension: {
          index: :x5608,
          strategy: :straight_multiplication,
          question: "How much do you expect your future monthly pension to be?",
          type: :select,
          answer_options: [0, 1, 2, 3, 4, 5, 6],
          select_options: [
            [0, '$0'],
            [1, '$1 to $499'],
            [2, '$500 to $999'],
            [3, '$1,000 to $1,999'],
            [4, '$2,000 to $4,999'],
            [5, '$5,000 to $9,999'],
            [6, 'over $10,000']
          ]
        },

        inheritance: {
          index: :x5821,
          strategy: :straight_multiplication,
          question: "About how much in future inheritance (or transfer of assets) do you expect?",
          type: :select,
          answer_options: [0, 1, 2, 3, 4, 5, 6],
          select_options: [
            [0, '$0'],
            [1, '$1 to $10,000'],
            [2, '$10,000 to $50,000'],
            [3, '$50,000 to $100,000'],
            [4, '$100,000 to $500,000'],
            [5, '$500,000 to $1,000,000'],
            [6, 'over $1,000,000']
          ]
        },

        bequeath: {
          index: :x5825,
          strategy: :straight_multiplication,
          question: "Do you expect to leave a sizable estate to others?",
          type: :select,
          answer_options: [0, 1],
          select_options: [
            [0, 'Yes'],
            [1, 'No']
          ]
        },

        degree: {
          index: :x5905,
          strategy: :straight_multiplication,
          question: "What is the highest degree you have earned?",
          type: :select,
          answer_options: [1, 2, 3, 4, 5],
          select_options: [
            [1, 'Nursing, Chiropratic, other'],
            [2, "Associate's, junior college"],
            [3, "Bachelor's degree"],
            [4, 'MA, MS, MBA'],
            [5, 'PhD, MD, Law, JD, other doct.']
          ]
        },

        loan: {
          index: :x7131,
          strategy: :straight_multiplication,
          question: 'Have you applied for any type of credit or loan in the last 5 years?',
          type: :select,
          answer_options: [0, 1],
          select_options: [
            [0, 'Yes'],
            [1, 'No']
          ]
        },

        forseeable_expenses: {
          index: :x7186,
          strategy: :straight_multiplication,
          question: "You are currently saving for forseeable future expenses.",
          type: :select,
          answer_options: [0, 1],
          select_options: [
            [0, 'Yes'],
            [1, 'No']
          ]
        },

        emergency_fund: {
          index: :x7187,
          strategy: :straight_multiplication,
          question: "About how much do you think you need to have in savings for emergencies and other unexpected things that may come up?",
          type: :select,
          answer_options: [0, 1, 2, 3, 4, 5, 6],
          select_options: [
            [0, '$0'],
            [1, '$1 to $10,000'],
            [2, '$10,000 to $50,000'],
            [3, '$50,000 to $100,000'],
            [4, '$100,000 to $500,000'],
            [5, '$500,000 to $1,000,000'],
            [6, 'over $1,000,000']
          ]
        },

        job_title: {
          index: :x7401,
          strategy: :custom,
          question: "Which of the following closely matches your job title?",
          type: :select,
          answer_options: [0, 1, 2],
          select_options: [
            [0, "Managerial, Executive"],
            [1, "Technical, Sales, Administrative"],
            [2, "Operator, Fabricator, Laborer"]
          ]
          ### MAPPING:
          # 0? -- x7401_1 == 1, otherwise x7401_1 == 0
          # 1? -- x7401_2 == 1, otherwise x7401_2 == 0
          # 2? -- x7401_5 == 1, otherwise x7401_5 == 0
        }

      }

    end

    def coefficients
      # Some of the keys were modified from the original paper to make life easier
      # e.g. x5825_3 changed to x5825 as it is the only question with that
      # identifier. Noted below where changed.

      # Y=1 : 21-40% stocks
      # Y=2 : 41-60% stocks
      # Y=3 : 61-80% stocks
      # Y=4 : 81-100% stocks

     @coefficients ||= {
                  # Prob[Y=1]  Prob[Y=2]  Prob[Y=3]  Prob[Y=4]
        constant: [ 0.1129,    0.0138,    -0.4407,    0.4576  ],
        x101:     [ 0.0090,    0.0203,    -0.0772,    -0.1354 ],
        x1706:    [ -0.0775,   -0.0679,   -0.0684,    0.0334  ],
        x3006_1:  [ 0.0291,    0.2046,    0.0805,     -0.8612 ],
        x3006_5:  [ 0.2607,    0.3768,    0.3226,     0.5412  ],
        x3008_1:  [ -0.0058,   -0.5741,   -0.205,     0.1135  ],
        x3008_45: [ -0.1432,   -0.4317,   -0.2222,    -0.24   ],
        x301_1:   [ -0.3845,   -0.272,    -0.3285,    -0.069  ],
        x303_3:   [ -0.3547,   -0.7043,   -0.6356,    -0.3611 ],
        # x3014_1:  [ 0.0849,    0.0417,    0.5145,      0.3458 ], # Excluded b/c question essentially the same as 3014.4 and .4 is more statistically significant
        x3014:    [ -0.454,    -0.743,    -0.5089,    -0.1988 ], # Modified from 3014_4
        x432:     [  0.0796,   -0.0686,   0.0251,     -0.5659 ], # Modified from 432_1
        x5608:    [ -0.1078,   0.0522,    -0.2318,    -0.1235 ],
        x5821:    [ -0.0213,   -0.0373,   -0.0671,    -0.048  ],
        x5825:    [ -0.1321,   0.1095,    0.1147,     -0.1157 ], # Modified from 5825_3
        x5905:    [ -0.0353,   0.0591,    -0.0178,    -0.0482 ],
        x7131:    [ 0.0588,    -0.1225,   -0.5052,    -0.4059 ],
        x7186:    [ -0.0835,   -0.2242,   -0.3583,    -0.0026 ],
        x7187:    [ 0.0787,    0.1547,    0.0801,     0.0739  ],
        x7372:    [ 0.3586,    0.1602,    0.6719,     0.0548  ], # Modified from 7372_1
        x7401_1:  [ -0.2267,   -0.35,     0.1345,     -0.4321 ],
        x7401_2:  [ 0.0897,    -0.0048,   0.2497,     -0.2006 ],
        x7401_5:  [ -0.5399,   -0.9636,   -0.1089,    -0.1223 ],
        x8021:    [ -0.5145,   -0.1026,   -0.0763,    0.0643  ], # Modified from 8021_1
        x8022:    [ 0.0048,    -0.0001,   0.0009,     0.0004  ]
      }
    end

  end
end
