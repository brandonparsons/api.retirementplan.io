class RegularUser < User
  has_secure_password

  validates :password, length: { minimum: 6 }, allow_nil: true
end
