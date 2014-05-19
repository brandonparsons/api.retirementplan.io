require 'spec_helper'

describe Api::V1::QuestionnairesController do

  describe "GET index" do
    context "logged out" do
      it "does not permit request" do
        create(:questionnaire)
        get :index
        expect(response.response_code).to eql(401)
      end
    end # logged out

    context "logged in" do
      before(:each) do
        @user = create(:user)
        @q    = create(:questionnaire, user: @user)
        Api::V1::QuestionnairesController.any_instance.stub(:current_user).and_return(@user)
      end

      it "returns array, with single entry being current user's questionnaire" do
        create(:questionnaire)
        create(:questionnaire)
        get :index
        expect(response.response_code).to eql(200)
        j = JSON.parse(response.body)
        j.should include("questionnaires")
        expect(j['questionnaires'].is_a?(Array)).to be_true
        expect(j['questionnaires'].length).to eql(1)
        expect(j['questionnaires'][0]['id']).to eql(@q.id)
      end
    end # logged in
  end # GET index


  describe "POST create" do
    context "logged out" do
      before(:each) do
        @attrs = attributes_for(:questionnaire)
      end

      it "Doesn't allow create" do
        post :create, questionnaire: @attrs
        expect(response.response_code).to eql(401)
      end
    end # logged out

    context "logged in" do
      before(:each) do
        @user = create(:user)
        @attrs = attributes_for(:questionnaire)
        @attrs.delete(:user_id)
        @attrs.delete(:id)
        Api::V1::QuestionnairesController.any_instance.stub(:current_user).and_return(@user)
      end

      it "returns proper JSON if valid params" do
        post :create, questionnaire: @attrs
        expect(response.response_code).to eql(201)
        json = JSON.parse(response.body)
        json.should include("questionnaire")
      end

      it "returns 422 if user already has a questionnaire" do
        @questionnaire = create(:questionnaire, user: @user)
        post :create, questionnaire: @attrs
        expect(response.response_code).to eql(422)
        json = JSON.parse(response.body)
        json["message"].should match(/have already created/i)
      end

      it "returns errors/422 if invalid params" do
        invalid_attrs = @attrs.merge({age: -1})
        post :create, questionnaire: invalid_attrs
        expect(response.response_code).to eql(422)
        json = JSON.parse(response.body)
        json.should include("age")
        json["age"].should include("must be greater than 0")
      end

      it "doesn't allow unpermitted params" do
        post :create, booyah: @attrs.merge({admin: true})
        expect(response.response_code).to eql(422)
        json = JSON.parse(response.body)
        json["message"].should match(/missing parameters/i)
      end

      it "doesnt allow someone to include user_id and modify another user" do
        user2 = create(:user)
        post :create, questionnaire: @attrs.merge({user_id: user2.id})
        expect(response.response_code).to eql(201)
        expect(user2.questionnaire).to be_nil
      end
    end # logged in
  end # POST create

  describe "PUT update" do
    context "logged out" do
      before(:each) do
        @attrs = attributes_for(:questionnaire)
      end

      it "Doesn't allow update" do
        q = create(:questionnaire)
        put :update, questionnaire: @attrs, id: q.id
        expect(response.response_code).to eql(401)
      end
    end # logged out

    context "logged in" do
      before(:each) do
        @user = create(:user)
        @questionnaire = create(:questionnaire, user: @user)
        @attrs = attributes_for(:questionnaire)
        @attrs.delete(:user_id)
        @attrs.delete(:id)
        Api::V1::QuestionnairesController.any_instance.stub(:current_user).and_return(@user)
      end

      it "returns proper JSON if valid params" do
        put :update, questionnaire: @attrs.merge({age: 16}), id: @questionnaire.id
        expect(response.response_code).to eql(200)
        json = JSON.parse(response.body)
        json.should include("questionnaire")
        json["questionnaire"]["age"].should eql(16)
      end

      it "returns errors/422 if invalid params" do
        put :update, questionnaire: @attrs.merge({age: -1}), id: @questionnaire.id
        expect(response.response_code).to eql(422)
        json = JSON.parse(response.body)
        json.should include("age")
        json["age"].should include("must be greater than 0")
      end

      it "doesn't allow unpermitted params" do
        put :update, booyay: @attrs, id: @questionnaire.id
        expect(response.response_code).to eql(422)
        json = JSON.parse(response.body)
        json["message"].should match(/missing parameters/i)
      end
    end # logged in
  end # PUT update

end
