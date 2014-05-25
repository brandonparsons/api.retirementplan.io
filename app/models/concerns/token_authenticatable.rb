module TokenAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_create :ensure_authentication_token
  end

  module ClassMethods
    def authenticate_from_email_and_token(email, auth_token)
      return nil unless email.present? && auth_token.present?

      user = User.find_by(email: email)

      if user && secure_compare(user.authentication_token, auth_token)
        return user
      else
        return nil
      end
    end

    private

    def secure_compare(a, b)
      # From Devise.secure_compare
      return false if a.blank? || b.blank? || a.bytesize != b.bytesize
      l = a.unpack "C#{a.bytesize}"

      res = 0
      b.each_byte { |byte| res |= byte ^ l.shift }
      res == 0
    end
  end

  def ensure_authentication_token
    if authentication_token.blank?
      self.authentication_token = generate_authentication_token
    end
  end

  def reset_authentication_token
    self.authentication_token = generate_authentication_token
  end

  def reset_authentication_token!
    reset_authentication_token
    save!
  end

  def clear_authentication_token!
    self.authentication_token = nil
    save!
  end

  def sign_in!
    raise "#sign_in! method needs to be implemented."
  end

  def sign_out!
    raise "#sign_out! method needs to be implemented."
  end


  private

  def generate_authentication_token
    loop do
      token = friendly_token
      break token unless self.class.unscoped.find_by(authentication_token: token)
    end
  end

  def friendly_token
    # From Devise.friendly_token, changed to 15 long
    SecureRandom.urlsafe_base64(20).tr('lIO0', 'sxyz')
  end
end
