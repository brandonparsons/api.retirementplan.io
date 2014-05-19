require 'spec_helper'

describe Api::V1::UsersController do

  describe "GET index" do
    context "logged out" do
      it "returns []" do
        create(:user)
        get :index
        expect(response.response_code).to eql(200)
        j = JSON.parse(response.body)
        j.should include('users')
        expect(j['users']).to eql([])
      end
    end

    context "logged in" do
      before(:each) do
        @user = create(:user)
        Api::V1::UsersController.any_instance.stub(:current_user).and_return(@user)
      end

      it "returns array, with single entry being current user" do
        get :index
        create(:user)
        create(:user)
        expect(response.response_code).to eql(200)
        j = JSON.parse(response.body)
        j.should include("users")
        expect(j['users'].is_a?(Array)).to be_true
        expect(j['users'].length).to eql(1)
        j['users'][0]["email"].should eql(@user.email)
      end
    end
  end

  describe "POST create" do
    # No login required
    before(:each) do
      @attrs = attributes_for(:user)
      @attrs.delete(:id)
    end

    context "Logged out" do
      it "creates a user if valid parameters" do
        expect(User.count).to eql(0)
        post :create, user: @attrs
        expect(response.response_code).to eql(201)
        expect(User.count).to eql(1)
        expect(User.last.email).to eql(@attrs[:email])
        json = JSON.parse(response.body)
        json.should include("access_token")
      end

      it "returns 422 on invalid parameters" do
        invalid_attrs = @attrs.merge({email: "joe"})
        post :create, user: invalid_attrs
        expect(response.response_code).to eql(422)
        json = JSON.parse(response.body)
        json.should include("email")
        json["email"].should include("is invalid")
      end

      it "doesnt allow unpermitted params" do
        invalid_attrs = @attrs.merge({admin: "true"})
        post :create, user: invalid_attrs
        expect(response.response_code).to eql(422)
      end
    end
  end

  describe "POST update_profile" do
    before(:each) do
      @attrs = attributes_for(:user)
      @attrs[:current_password] = @attrs[:password]
      @attrs.delete :password
      @attrs.delete :password_confirmation
      @attrs.delete :id
      @user = create(:user, password: 'asdfasdf', password_confirmation: 'asdfasdf')
    end

    context "Logged out" do
      it "doesn't allow updates, even if valid" do
        post :update_profile, user: @attrs
        expect(response.response_code).to eql(401)
      end
    end

    context "Logged in" do
      before(:each) do
        Api::V1::UsersController.any_instance.stub(:current_user).and_return(@user)
      end

      it "updates the user when given valid attrs, does not change password" do
        updated_attrs = @attrs.merge({email: "superman@what.com"})
        post :update_profile, user: updated_attrs
        expect(response.response_code).to eql(200)
        json = JSON.parse(response.body)
        expect(json).to include("user")
        expect(json["user"]["email"]).to eql("superman@what.com")
        expect(@user.authenticate("asdfasdf")).to be_true
      end

      it "requires a current password to change attrs" do
        updated_attrs = @attrs.merge({
          email: "superman@what.com",
        })
        updated_attrs.delete :current_password
        post :update_profile, user: updated_attrs
        expect(response.response_code).to eql(401)
      end

      it "requires the correct current password to change attrs" do
        updated_attrs = @attrs.merge({
          email: "superman@what.com",
          current_password: "incorrectCurrentPassword"
        })
        post :update_profile, user: updated_attrs
        expect(response.response_code).to eql(401)
      end

      it "returns 422 if invalid attrs" do
        updated_attrs = @attrs.merge({email: "superman"})
        post :update_profile, user: updated_attrs
        expect(response.response_code).to eql(422)
        json = JSON.parse(response.body)
        json.should include("errors")
        expect(json["errors"]["email"]).to include("is invalid")
      end

      it "cant update sensitive attributes" do
        updated_attrs = @attrs.merge({admin: true, email: "superman@what.com"})
        post :update_profile, user: updated_attrs
        expect(response.response_code).to eql(422)
        @user.reload
        expect(@user.admin).to be_false
      end

      it "can't update the password" do
        @attrs[:password] = 'mynewpassword'
        @attrs[:password_confirmation] = 'mynewpassword'
        expect(@user.authenticate("asdfasdf")).to be_true
        post :update_profile, user: @attrs
        expect(response.response_code).to eql(422)
        @user.reload
        expect(@user.authenticate("mynewpassword")).to be_false
        expect(@user.authenticate("asdfasdf")).to be_true
      end

      it "Can't update other user's profiles" do
        user2 = create(:user)
        updated_attrs = @attrs.merge({email: "superman@what.com"})
        post :update_profile, user: updated_attrs, id: user2.id
        expect(response.response_code).to eql(200)
        json = JSON.parse(response.body)
        expect(json).to include("user")
        @user.reload
        user2.reload
        expect(@user.email).to eql("superman@what.com")
        expect(user2.email).not_to eql("superman@what.com")
      end

    end # logged-in
  end # PUT update


  describe "POST change_password" do
    before(:each) do
      @user = create(:user, password: 'asdfasdf', password_confirmation: 'asdfasdf')
      @valid_attrs = {
        current_password: 'asdfasdf',
        password: 'mynewpassword',
        password_confirmation: 'mynewpassword'
      }
    end

    context "Logged out" do
      it "doesn't allow change, even if valid" do
        post :change_password, user: @valid_attrs, id: @user.id
        expect(response.response_code).to eql(401)
      end
    end

    context "Logged in" do
      before(:each) do
        Api::V1::UsersController.any_instance.stub(:current_user).and_return(@user)
      end

      it "updates the password if matching pass & conf & has old password" do
        expect(@user.authenticate("asdfasdf")).to be_true
        post :change_password, user: @valid_attrs
        expect(response.response_code).to eql(200)
        expect(@user.authenticate("mynewpassword")).to be_true
      end

      it "doesnt let you specify another user id, even if valid" do
        user2 = create(:user)
        post :change_password, id: user2.id, user: @valid_attrs
        expect(response.response_code).to eql(200)
        expect(@user.authenticate("mynewpassword")).to be_true
        expect(user2.authenticate("mynewpassword")).to be_false
        expect(user2.authenticate("asdfasdf")).to be_true
      end

      it "doesnt update password if current pass incorrect" do
        updated_attrs = @valid_attrs.merge({
          password: 'mynewpassword',
          password_confirmation: 'mynewpassword',
          current_password: 'invalid'
        })
        post :change_password, user: updated_attrs
        expect(response.response_code).to eql(401)
        expect(@user.authenticate("mynewpassword")).to be_false
        expect(@user.authenticate("asdfasdf")).to be_true
      end

      it "doesnt update password if current password blank" do
        updated_attrs = @valid_attrs.merge({
          password: "mynewpassword",
          password_confirmation: "mynewpassword",
          current_password: ""
        })
        post :change_password, user: updated_attrs
        expect(response.response_code).to eql(401)
        expect(@user.authenticate("mynewpassword")).to be_false
        expect(@user.authenticate("asdfasdf")).to be_true
      end

      it "doesn't update the password if confirmation doesnt match password" do
        expect(@user.authenticate("asdfasdf")).to be_true
        updated_attrs = @valid_attrs.merge({
          password: "mynewpassword",
          password_confirmation: "doesntmatch",
          current_password: 'asdfasdf'
        })
        post :change_password, user: updated_attrs
        expect(response.response_code).to eql(422)
        @user.reload
        expect(@user.authenticate("mynewpassword")).to be_false
        expect(@user.authenticate("asdfasdf")).to be_true
      end
    end
  end # POST change_password



end
