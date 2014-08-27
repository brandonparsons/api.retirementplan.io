module HideDeleted
  extend ActiveSupport::Concern

  included do
    default_scope { where(deleted_at: nil) }
  end

  module ClassMethods
    def deleted
      self.unscoped.where.not(deleted_at: nil)
    end
  end

end
