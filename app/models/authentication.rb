class Authentication < ActiveRecord::Base
  # Contains OAuth data from third parties: Facebook, Twitter, etc.

  belongs_to :user

  validates :uid, presence: true, uniqueness: { scope: :provider }

  def self.pretty_provider(provider)
    provider = provider.to_s
    provider == 'linkedin' ? "LinkedIn" : provider.titleize
  end

end
