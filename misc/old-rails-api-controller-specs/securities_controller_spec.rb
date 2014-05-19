require 'spec_helper'

describe Api::V1::SecuritiesController do

  describe "GET index" do

    context "logged out" do
      it "doesn't return anything" do
        get :index
        expect(response.response_code).to eql(401)
      end
    end

    context "logged in" do
      before(:each) do
        @user = create(:user)
        @s = create(:security)
        Api::V1::SecuritiesController.any_instance.stub(:current_user).and_return(@user)
      end

      it "returns all EF's" do
        get :index
        expect(response.response_code).to eql(200)
        j = JSON.parse(response.body)
        j.should include('securities')
        j['securities'].should be_a(Array)
        expect(j['securities'][0]['id']).to eql(@s.id)
      end
    end

  end

end
