class QuestionnaireSerializer < ApiSerializer
  attributes :id, :age, :sex, :no_people, :real_estate_val, :saving_reason,
    :investment_timeline, :investment_timeline_length, :economy_performance,
    :financial_risk, :credit_card, :pension, :inheritance, :bequeath, :degree,
    :loan, :forseeable_expenses, :married, :emergency_fund, :job_title, :investment_experience
end
