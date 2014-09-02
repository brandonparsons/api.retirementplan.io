class Expense < ActiveRecord::Base

  ALLOWABLE_FREQUENCIES = %w{ weekly monthly annual onetime }


  ################
  # ASSOCIATIONS #
  ################

  belongs_to :user, touch: true


  #############
  # CALLBACKS #
  #############

  before_validation do
    # The client has a habit of sending both times if you've swapped one for the
    # other. Enforce consistency here.
    frequency == 'onetime' ? self.ends = nil : self.onetime_on = nil
  end


  ###############
  # VALIDATIONS #
  ###############

  validates :user_id,         presence: true
  validates :description,     presence: true
  validates :amount,          presence: true, numericality: {greater_than: 0}
  validates :frequency,       presence: true, inclusion: { :in => ALLOWABLE_FREQUENCIES }
  validates :onetime_on,      presence: true, if: ->(expense) {expense.frequency == 'onetime'}
  validates :is_added,        inclusion: { :in => [true, false] }


  #################
  # CLASS METHODS #
  #################

  def self.create_default_expenses_for(user_id)
    expenses = []
    default_expenses.each do |expense_details|
      expenses << create!(expense_details.merge({user_id: user_id}))
    end
    return expenses
  end


  private

  def self.default_expenses
    return [
      # Weekly
      {
        "description" => "Coffee",
        "amount" => 15,
        "frequency" => "weekly",
        "ends" => Time.zone.now + 5.years,
        "is_added" => false
      },
      {
        "description" => "Fuel",
        "amount" => 40,
        "frequency" => "weekly",
        "is_added" => true
      },

      # Monthly
      {
        "description" => "Food",
        "amount" => 500,
        "frequency" => "monthly",
        "is_added" => true
      },
      {
        "description" => "Rent/Mortgage",
        "amount" => 2000,
        "frequency" => "monthly",
        "is_added" => true
      },
      {
        "description" => "Utilities",
        "amount" => 200,
        "frequency" => "monthly",
        "is_added" => true
      },
      {
        "description" => "TV/Internet",
        "amount" => 100,
        "frequency" => "monthly",
        "is_added" => true
      },
      {
        "description" => "Cell Phones",
        "amount" => 100,
        "frequency" => "monthly",
        "is_added" => true
      },
      {
        "description" => "Entertainment",
        "amount" => 300,
        "frequency" => "monthly",
        "is_added" => true
      },
      {
        "description" => "Insurance",
        "amount" => 250,
        "frequency" => "monthly",
        "is_added" => true
      },
      {
        "description" => "Car Payments/Maint.",
        "amount" => 400,
        "frequency" => "monthly",
        "is_added" => true
      },

      # Annual
      {
        "description" => "Vacation",
        "amount" => 2000,
        "frequency" => "annual",
        "is_added" => false
      },
      {
        "description" => "Gifts",
        "amount" => 500,
        "frequency" => "annual",
        "is_added" => false
      },
      {
        "description" => "Donations",
        "amount" => 500,
        "frequency" => "annual",
        "is_added" => false
      },

      # One-time
      {
        "description" => "Sports Car",
        "amount" => 25000,
        "frequency" => "onetime",
        "onetime_on" => Time.zone.now + 1.year + 2.months,
        "is_added" => false
      }
    ]
  end

end
