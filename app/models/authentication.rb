class Authentication < ActiveRecord::Base
  # OAuth data from providers -Facebook, Google, etc.

  ################
  # ASSOCIATIONS #
  ################

  belongs_to :user, touch: true


  ###############
  # VALIDATIONS #
  ###############

  validates :uid, presence: true, uniqueness: { scope: :provider }

end
