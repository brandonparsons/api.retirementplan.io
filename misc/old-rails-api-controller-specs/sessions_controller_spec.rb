require 'spec_helper'

describe Api::V1::SessionsController do

  describe "POST create" do
    it "returns missing parameters if missing password" do
      post :create, username: "Superbob"
      expect(response.response_code).to eql(422)
      JSON.parse(response.body)["success"].should be_false
    end

    it "returns missing parameters if missing username" do
      post :create, password: "Superbob"
      expect(response.response_code).to eql(422)
      JSON.parse(response.body)["success"].should be_false
    end

    it "returns invalid grant if no valid user" do
      post :create, username: "bob@what.com", password: "Superbob"
      expect(response.response_code).to eql(403)
      JSON.parse(response.body)["success"].should be_false
    end

    it "returns successful response if valid user" do
      create(:user, email: "bob@what.com", password: "Superbob", password_confirmation: "Superbob")
      post :create, username: "bob@what.com", password: "Superbob"
      expect(response.response_code).to eql(200)
      JSON.parse(response.body)["success"].should be_true
      JSON.parse(response.body)["access_token"].should_not be_nil
    end

    it "calls sign_in! on user if successful" do
      create(:user, email: "bob@what.com", password: "Superbob", password_confirmation: "Superbob")
      @user = User.find_by(email: "bob@what.com")
      count = @user.sign_in_count
      post :create, username: "bob@what.com", password: "Superbob"
      @user.reload
      @user.sign_in_count.should eql(count+1)
    end
  end

  describe "DELETE destroy" do
    it "requires authenticated user" do
      delete :destroy, id: "current"
      expect(response.response_code).to eql(401)
    end

    it "signs out the current user, returns successful response" do
      @user = build_stubbed(:user)
      Api::V1::SessionsController.any_instance.stub(:current_user).and_return(@user)
      delete :destroy, id: "current"
      expect(response.response_code).to eql(200)
      JSON.parse(response.body)["success"].should be_true
    end
  end

end
