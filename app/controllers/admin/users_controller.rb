module Admin
  class UsersController < AdminController
    def index
      render json: User.all, each_serializer: AdminUserSerializer
    end
  end
end
