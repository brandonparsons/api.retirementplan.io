class RegularUser < User

  has_secure_password


  # When looking up RegularUser in the database (for checking against supplied
  # password, don't want to return users who have no password (e.g. OAuth users
  # who have never reset their password).
  default_scope { where.not(password_digest: nil) }


  ###############
  # VALIDATIONS #
  ###############

  validates :password, length: { minimum: 6 }, allow_nil: true


  #################
  # CLASS METHODS #
  #################

  def self.normalized_timestamp
    Time.now.utc.to_i
  end

  def self.find_from_all_users_with_email(email)
    # Unscoped as default scope searches for users *with* a password digest.
    # If a person from OAuth wants to reset/set a password, allow them (therefore
    # need to list them in find results.)
    unscoped.find_by(email: email)
  end

  def self.find_from_all_users_with_id(id)
    # See comment in ::find_from_all_users_with_email
    unscoped.find_by(id: id)
  end


  ####################
  # INSTANCE METHODS #
  ####################

  def password_reset_token
    verifier = self.class.verifier_for('password-reset')
    verifier.generate([id, self.class.normalized_timestamp])
  end

end
