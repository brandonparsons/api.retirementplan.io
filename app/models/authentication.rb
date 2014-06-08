class Authentication < ActiveRecord::Base
  # Contains OAuth data from third parties: Facebook, Google, etc.

  belongs_to :user, touch: true

  validates :uid, presence: true, uniqueness: { scope: :provider }
end
