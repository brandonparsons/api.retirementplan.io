class AdminUserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :simulations_ran, :created_at,
    :confirmed, :accepted_terms, :has_completed_questionnaire,
    :has_selected_portfolio, :has_selected_expenses, :has_simulation_input,
    :has_completed_simulation, :has_selected_etfs, :has_tracked_portfolio
end
