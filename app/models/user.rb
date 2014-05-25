class User < ActiveRecord::Base

  include TokenAuthenticatable

  hstore_accessor :data,
    has_selected_expenses:    :boolean,
    has_completed_simulation: :boolean,
    min_rebalance_spacing:    :integer,
    max_contact_frequency:    :integer,
    last_contact:             :integer,
    allowable_drift:          :integer,
    simulations_ran:          :integer


  ################
  # ASSOCIATIONS #
  ################

  has_one     :questionnaire,                     dependent: :destroy
  has_one     :portfolio,                         dependent: :destroy
  has_one     :retirement_simulation_parameters,  dependent: :destroy
  has_many    :expenses,                          dependent: :destroy
  has_many    :authentications,                   dependent: :destroy


  #############
  # CALLBACKS #
  #############

  before_validation on: :create do
    self.min_rebalance_spacing  = 90.days
    self.max_contact_frequency  = 7.days
    self.allowable_drift        = 5
    self.last_contact           = Time.zone.now.to_i
    self.simulations_ran        = 0
  end


  ###############
  # VALIDATIONS #
  ###############

  validates :from_oauth,            inclusion: { in: [true, false] }
  validates :min_rebalance_spacing, presence: true, numericality: {greater_than_or_equal_to: 1.day, message: "must be at least one day"}
  validates :max_contact_frequency, presence: true, numericality: {greater_than_or_equal_to: 1.day, message: "must be at least one day"}
  validates :allowable_drift,       presence: true, numericality: {greater_than_or_equal_to: 1, less_than_or_equal_to: 50}


  #################
  # CLASS METHODS #
  #################

  def self.with_tracked_portfolios
    # Returns all users who have a tracked portfolio.
    Portfolio.all.select { |portfolio| portfolio.tracking? }.map(&:user)
  end


  ####################
  # INSTANCE METHODS #
  ####################

  def has_accepted_terms?
    accepted_terms.present?
  end

  def accept_terms!
    self.accepted_terms = Time.zone.now
    save!
  end

  def has_questionnaire?
    !!questionnaire
  end

  def has_completed_questionnaire?
    has_questionnaire? && questionnaire.complete?
  end

  def is_male?
    raise "Questionnaire not complete." unless has_completed_questionnaire?
    questionnaire.sex == 1
  end

  def is_married?
    raise "Questionnaire not complete." unless has_completed_questionnaire?
    questionnaire.married == 1
  end

  def age
    raise "Questionnaire not complete." unless has_completed_questionnaire?
    questionnaire.age
  end

  def has_selected_portfolio?
    portfolio.present?
  end

  def allowable_securities
    portfolio && portfolio.weights.keys
  end

  def has_selected_expenses!
    self.has_selected_expenses = true
    save!
  end

  def has_defined_simulation_parameters?
    !!retirement_simulation_parameters
  end

  def has_completed_simulation!
    self.has_completed_simulation = true
    save!
  end

  def has_setup_tracked_portfolio?
    portfolio && portfolio.tracking?
  end

  def send_etf_purchase_instructions(rebalance_amount)
    UserMailer.delay.etf_purchase_instructions(id, rebalance_amount)
  end

  def check_portfolio_balance
    if portfolio_out_of_balance?
      send_out_of_balance_email if can_contact?
    else
      send_min_rebalance_spacing_email if exceeded_max_rebalance_frequency
    end
  end

  def ran_simulations!(number)
    begin
      self.simulations_ran = simulations_ran + Integer(number)
      save
    rescue
      false
    end
  end

  def confirm!
    self.confirmed_at = Time.zone.now
    save!
  end

  # def has_facebook?
  #   accounts.where(provider: 'facebook').any?
  # end

  # def has_twitter?
  #   accounts.where(provider: 'twitter').any?
  # end

  def sign_in!
    self.last_sign_in_at = Time.zone.now
    increment(:sign_in_count)
    reset_authentication_token
    save!
  end

  def sign_out!
    clear_authentication_token!
  end

  def notify_admin_of_signup!
    ::AdminMailer.delay.user_sign_up(user.id)
  end


  private

  def portfolio_out_of_balance?
    decimal_allowable_drift = allowable_drift.to_f / 100
    portfolio.out_of_balance?(decimal_allowable_drift)
  end

  def can_contact?
    (Time.zone.now.to_i - last_contact) > max_contact_frequency
  end

  def contact!
    self.last_contact = Time.zone.now.to_i
    save!
  end

  def exceeded_max_rebalance_frequency
    (Time.zone.now.to_i - last_contact) > min_rebalance_spacing
  end

  def send_out_of_balance_email
    contact!
    UserMailer.delay.portfolio_out_of_balance(id)
  end

  def send_min_rebalance_spacing_email
    contact!
    UserMailer.delay.min_rebalance_spacing(id)
  end

end
