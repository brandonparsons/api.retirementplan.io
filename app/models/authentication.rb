class Authentication < ActiveRecord::Base
  # Contains OAuth data from third parties: Facebook, Google, etc.

  scope :first, -> { order("created_at").first }
  scope :last, -> { order("created_at DESC").first }

  belongs_to :user, touch: true

  validates :uid, presence: true, uniqueness: { scope: :provider }
end
