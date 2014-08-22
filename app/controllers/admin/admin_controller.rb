module Admin
  class AdminController < ApplicationController
    before_action :authenticate_user!
    before_action :must_be_admin!

    protected

    def must_be_admin!
      if current_user.admin?
        true
      else
        access_denied
        false
      end
    end
  end
end
