require 'spec_helper'

describe Api::V1::EtfsController do

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
        @e = create(:etf)
        Api::V1::EtfsController.any_instance.stub(:current_user).and_return(@user)
      end

      it "returns all EF's" do
        get :index
        expect(response.response_code).to eql(200)
        j = JSON.parse(response.body)
        j.should include('etfs')
        j['etfs'].should be_a(Array)
        expect(j['etfs'][0]['id']).to eql(@e.id)
      end
    end

  end

end
