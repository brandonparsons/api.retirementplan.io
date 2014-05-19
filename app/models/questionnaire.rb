class Questionnaire < ActiveRecord::Base

  ################
  # ASSOCIATIONS #
  ################

  belongs_to :user


  #############
  # CALLBACKS #
  #############

  before_save :calculate_pratt_arrows


  ###############
  # VALIDATIONS #
  ###############

  validates :user_id,                     presence: true

  validates :age,                         presence: true, numericality: {greater_than: 0, less_than: 120}
  validates :sex,                         presence: true, numericality: true, inclusion: { in: 0..1 }
  validates :no_people,                   presence: true, numericality: {greater_than: 0}
  validates :real_estate_val,             presence: true, numericality: true, inclusion: { in: 0..6 }
  validates :saving_reason,               presence: true, numericality: true, inclusion: { in: 0..1 }
  validates :investment_timeline,         presence: true, numericality: true, inclusion: { in: 0..1 }
  validates :investment_timeline_length,  presence: true, numericality: true, inclusion: { in: 0..1 }
  validates :economy_performance,         presence: true, numericality: true, inclusion: { in: 0..1 }
  validates :financial_risk,              presence: true, numericality: true, inclusion: { in: 0..1 }
  validates :credit_card,                 presence: true, numericality: true, inclusion: { in: 0..1 }
  validates :pension,                     presence: true, numericality: true, inclusion: { in: 0..6 }
  validates :inheritance,                 presence: true, numericality: true, inclusion: { in: 0..6 }
  validates :bequeath,                    presence: true, numericality: true, inclusion: { in: 0..1 }
  validates :degree,                      presence: true, numericality: true, inclusion: { in: 1..5 }
  validates :loan,                        presence: true, numericality: true, inclusion: { in: 0..1 }
  validates :forseeable_expenses,         presence: true, numericality: true, inclusion: { in: 0..1 }
  validates :married,                     presence: true, numericality: true, inclusion: { in: 0..1 }
  validates :emergency_fund,              presence: true, numericality: true, inclusion: { in: 0..6 }
  validates :job_title,                   presence: true, numericality: true, inclusion: { in: 0..2 }

  validates :investment_experience,       presence: true, numericality: true, inclusion: { in: 0..3 }

  ####################
  # INSTANCE METHODS #
  ####################

  def complete?
    self.pratt_arrow_low.present?
  end

  def questions
    Finance::RiskToleranceQuestionnaire.questions_for_form
  end


  private

  def calculate_pratt_arrows
    # Excludes investment experience - that was added after the fact, and not
    # included in the dissertation.
    answers = {
                             age: self.age,
                             sex: self.sex,
                       no_people: self.no_people,
                 real_estate_val: self.real_estate_val,
                   saving_reason: self.saving_reason,
             investment_timeline: self.investment_timeline,
      investment_timeline_length: self.investment_timeline_length,
             economy_performance: self.economy_performance,
                  financial_risk: self.financial_risk,
                     credit_card: self.credit_card,
                         pension: self.pension,
                     inheritance: self.inheritance,
                        bequeath: self.bequeath,
                          degree: self.degree,
                            loan: self.loan,
             forseeable_expenses: self.forseeable_expenses,
                         married: self.married,
                  emergency_fund: self.emergency_fund,
                       job_title: self.job_title
    }
    self.pratt_arrow_low, self.pratt_arrow_high = Finance::RiskToleranceQuestionnaire.process(answers)
  end

end
