module Admin
  class AdminController < ApplicationController
    before_action :authenticate_user!
    before_action :must_be_admin

    protected

    def must_be_admin
      return access_denied unless current_user.admin?
    end
  end
end
