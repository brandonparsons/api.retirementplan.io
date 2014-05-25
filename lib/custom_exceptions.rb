module CustomExceptions
  class InvalidOauthCredentials < StandardError; end
  class MissingParameters       < StandardError; end
  class InvalidParameters       < StandardError; end
  class UserExistsFromOauth     < StandardError; end
  class UserExistsWithPassword  < StandardError; end
end
