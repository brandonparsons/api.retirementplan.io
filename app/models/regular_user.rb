class RegularUser < User
  has_secure_password

  # When looking up RegularUser in the database (for checking against supplied
  # password, don't want to return users who have no password (e.g. OAuth users
  # who have never reset their password).
  default_scope { where.not(password_digest: nil) }

  validates :password, length: { minimum: 6 }, allow_nil: true
end
