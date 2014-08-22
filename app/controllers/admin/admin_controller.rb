module Admin
  class AdminController < ApplicationController
    before_action :authenticate_user!
    before_action :must_be_admin!

    protected

    def must_be_admin!
      if user_signed_in? && current_user.admin?
        true
      else
        access_denied
      end
    end
  end
end
