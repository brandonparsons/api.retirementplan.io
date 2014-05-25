require 'digest/md5'

class RegularUser < User
  has_secure_password

  validates_presence_of :name, :email
  validates :email, uniqueness: { case_sensitive: false }
  validates :email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }

  after_validation on: :create do
    email_hash = Digest::MD5.hexdigest(email.strip.downcase)
    self.image_url = "https://www.gravatar.com/avatar/#{email_hash}?d=identicon"
  end

end
