class SimulationInput < ActiveRecord::Base

  ################
  # ASSOCIATIONS #
  ################

  belongs_to :user, touch: true


  #############
  # CALLBACKS #
  #############

  before_validation do
    unless married
      self.expenses_multiplier      = nil

      if user_is_male
        self.female_age             = nil
        self.retirement_age_female  = nil
      else
        self.male_age               = nil
        self.retirement_age_male    = nil
      end
    end

    if user_retired
      self.retirement_age_male    = male_age    if male_age
      self.retirement_age_female  = female_age  if female_age
    end

    unless both_working_from_start
      self.fraction_for_single_income = nil
    end

    if both_retired_from_start
      self.retirement_expenses        = 100
      self.income                     = nil
      self.current_tax_rate           = nil
      self.fraction_for_single_income = nil # This may not be required due to check above (unless both_working_from_start), but leave just in case
      self.salary_increase            = nil
    end

    unless include_home
      self.sell_house_in            = nil
      self.new_home_relative_value  = nil
      self.home_value               = nil
    end

    true
  end


  ###############
  # VALIDATIONS #
  ###############

  validates :user_id, presence: true

  # Inclusion tests in lieu of presence: true
  validates :user_is_male,  inclusion: { in: [true, false] }
  validates :married,       inclusion: { in: [true, false] }
  validates :user_retired,  inclusion: { in: [true, false] }
  validates :include_home,  inclusion: { in: [true, false] }

  validates :assets,                    presence: true, numericality: {greater_than: 0}
  validates :retirement_income,         presence: true, numericality: {greater_than: 0}
  validates :retirement_expenses,       presence: true, numericality: {greater_than: 0} # If already retired, setting to 100% so no reduction factor taken

  validates :male_age,                  numericality: {greater_than: 0, less_than: 120}, allow_blank: true
  validates :female_age,                numericality: {greater_than: 0, less_than: 120}, allow_blank: true
  validates :retirement_age_male,       numericality: {greater_than: 0, less_than: 120}, allow_blank: true
  validates :retirement_age_female,     numericality: {greater_than: 0, less_than: 120}, allow_blank: true

  validates :expenses_inflation_index,  presence: true, numericality: {greater_than_or_equal_to: 0}
  validates :income_inflation_index,    presence: true, numericality: {greater_than_or_equal_to: 0}
  validates :retirement_tax_rate,       presence: true, numericality: {greater_than: 10, less_than: 90}
  validates :life_insurance,            presence: true, numericality: {greater_than_or_equal_to: 0}

  validates :income,                    numericality: {greater_than_or_equal_to: 0},      allow_blank: true
  validates :sell_house_in,             numericality: {greater_than: 0, less_than: 120},  allow_blank: true
  validates :new_home_relative_value,   numericality: {greater_than: 0, less_than: 200},  allow_blank: true
  validates :home_value,                numericality: {greater_than: 0},                  allow_blank: true
  validates :expenses_multiplier,       numericality: {greater_than: 0},                  allow_blank: true
  validates :current_tax_rate,          numericality: {greater_than: 10, less_than: 90},  allow_blank: true

  validates :salary_increase,             numericality: {greater_than_or_equal_to: 0, less_than: 50},  allow_blank: true
  validates :fraction_for_single_income,  numericality: {greater_than: 0, less_than_or_equal_to: 100}, allow_blank: true

  validate do # ages
    if user_is_male
      validates_presence_of :male_age
      validates_presence_of :female_age if married
    else
      validates_presence_of :female_age
      validates_presence_of :male_age if married
    end

    if married
      validates_presence_of :retirement_age_male, :retirement_age_female
    else
      if user_is_male
        validates_presence_of :retirement_age_male
      else
        validates_presence_of :retirement_age_female
      end
    end

    if !user_retired
      begin
        if married
          if (retirement_age_male < male_age) && (retirement_age_female < female_age)
            errors.add(:base, "Retirement ages do not agree with selection of whether or not people are retired from the start.")
          end
        elsif user_is_male
          if retirement_age_male < male_age
            errors.add(:base, "Retirement age does not agree with selection of whether or not people are retired from the start.")
          end
        else # female, not married
          if retirement_age_female < female_age
            errors.add(:base, "Retirement age does not agree with selection of whether or not people are retired from the start.")
          end
        end
      rescue
        # If somehow values get set to nil - blows up. Probably only a test case.
        errors.add(:base, "Retirement ages do not agree with retirement selection.")
      end
    end
  end

  validate do # other validations
    if include_home
      validates_presence_of :sell_house_in, :new_home_relative_value, :home_value
    end

    if married
      validates_presence_of :expenses_multiplier
      validates_presence_of :fraction_for_single_income if both_working_from_start
    end

    unless both_retired_from_start
      validates_presence_of :retirement_expenses, :current_tax_rate, :salary_increase, :income
    end
  end


  #################
  # CLASS METHODS #
  #################

  def self.default_for_user(user)
    properties = {
      expenses_inflation_index: 100,
      current_tax_rate:         35,
      salary_increase:          3,
      retirement_expenses:      100,
      retirement_tax_rate:      35,
      income_inflation_index:   0,
      expenses_multiplier:      1.6
    }

    # Nil returns if they haven't completed the questionnaire.  Should never
    # get here if that's the case, but guard anyway.
    properties[:user_is_male] = user.is_male?     if !user.is_male?.nil?
    properties[:married]      = user.is_married?  if !user.is_married?.nil?

    if !user.is_male?.nil?  && !user.age.nil?
      if user.is_male?
        properties[:male_age]   = user.age
      else
        properties[:female_age] = user.age
      end
    end

    return new(properties)
  end


  ####################
  # INSTANCE METHODS #
  ####################

  def both_retired_from_start
    retired_from_start = false

    begin
      male          = male_age.to_i
      male_retire   = retirement_age_male.to_i
      female        = female_age.to_i
      female_retire = retirement_age_female.to_i

      if married
        retired_from_start = (male_retire <= male) && (female_retire <= female)
      else
        if user_is_male
          retired_from_start = male_retire <= male
        else
          retired_from_start = female_retire <= female
        end
      end
    rescue
      retired_from_start = false
    end

    retired_from_start
  end

  def both_working_from_start
    both_working_from_start = false

    begin
      both_working_from_start = married &&
        (retirement_age_male.to_i > male_age.to_i) &&
        (retirement_age_female.to_i > female_age.to_i)
    rescue
      both_working_from_start = false
    end

    both_working_from_start
  end

end
