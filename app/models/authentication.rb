class Authentication < ActiveRecord::Base # OAuth data from providers -Facebook, Google, etc.
  include HideDeleted

  belongs_to :user, touch: true

  validates :uid, presence: true, uniqueness: { scope: :provider }
end
