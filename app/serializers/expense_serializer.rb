class ExpenseSerializer < ActiveModel::Serializer
  attributes :id, :description, :amount, :frequency, :ends, :onetime_on, :notes,
    :is_added

  def onetime_on
    object.onetime_on && object.onetime_on.utc.to_i
  end

  def ends
    object.ends && object.ends.utc.to_i
  end
end
