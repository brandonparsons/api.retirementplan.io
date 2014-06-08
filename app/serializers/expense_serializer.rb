class ExpenseSerializer < ActiveModel::Serializer
  attributes :description, :amount, :frequency, :ends, :onetime_on, :notes,
    :is_added

  # def onetime_on
  #   object.onetime_on && object.onetime_on.beginning_of_week.to_i * 1000
  # end

  # def ends
  #   object.ends && object.ends.beginning_of_week.to_i * 1000
  # end
end
