require 'spec_helper'

describe UserVerificationsController do
  render_views

  before(:each) do
    activate_authlogic
  end

  describe "GET show" do

    describe "with correct token" do

      before(:each) do
        @non_verified_user = Factory.create(:non_verified_user)
        @non_verified_user.reset_perishable_token!
        @token = @non_verified_user.perishable_token
      end

      it "should verify the user" do
        @non_verified_user.should_not be_verified
        get :show, :id => @token
        @non_verified_user.reload
        @non_verified_user.should be_verified
      end

      it "should redirect to home page with correct flash" do
        get :show, :id => @token
        response.should redirect_to profile_path
        signed_in?.should be_true
        flash[:success].should =~ /Thank you for verifying/i
        signed_in?.should be_true
      end

      it "should not re-verify the user if they have already verified" do
        @verified_user = Factory.create(:user)
        @verified_user.reset_perishable_token!
        token_new = @verified_user.perishable_token
        get :show, :id => token_new
        @verified_user.should be_verified
      end

    end

    describe "with incorrect token" do

      it "should redirect to the home page with the correct flash" do
        get :show, :id => "1948ndkfjRANDOM"
        response.should redirect_to new_user_verification_path
        flash[:error].should =~ /Unable to find your account - try again or contact us for assistance/i
      end

    end # incorrect

  end # get show

  describe "GET new" do

    it "should render the correct template, correct title and have a form for email" do
      get :new
      response.should render_template :new

      response.body.should have_selector("head title", :text => "User Verification")
      response.body.should have_selector("form")
    end

    it "should only get new if logged out" do
      @valid_user = Factory.create(:user)
      sign_in(@valid_user)
      get :new
      flash[:info].should =~ /You must be logged out/i
      response.should redirect_to dashboard_path
      response.code.should == "302" # redirected by require_no_user
    end
  end # get new

  describe "POST create" do

    describe "with successful email" do

      before(:each) do
        @non_verified_user = Factory.create(:non_verified_user)
        ActionMailer::Base.deliveries = []
        post :create, :email => @non_verified_user.email
      end

      it "should redirect to root with correct flash" do
        response.should redirect_to root_path
        flash[:info].should =~ /We are re-sending verification instructions to your email/i
      end

      it "should send an email" do
        ActionMailer::Base.deliveries.count.should == 1
        ActionMailer::Base.deliveries.last.subject.should =~ /Verification Instructions/i
      end

      it "should have the correct token in the email" do
        email = ActionMailer::Base.deliveries.last
        #message is now multipart, make sure both parts include perishable token
        token = User.find_by_email(@non_verified_user.email).perishable_token
        email.parts[0].body.to_s.should include token
        email.parts[1].body.to_s.should include token
      end
    end

    describe "failure" do

      it "should not work if logged in" do
        @valid_user = Factory.create(:user)
        sign_in(@valid_user)
        post :create, :email => @valid_user.email
        flash[:info].should =~ /You must be logged out/i
        response.should redirect_to dashboard_path
        response.code.should == "302" # redirected by require_no_user
      end

    end

    describe "with invalid email" do

      it "should redirect to root with correct flash" do
        post :create, :email => "invalid-yo@test.com"
        response.should redirect_to root_path
        flash[:error].should =~ /We still can't find your account.  Perhaps/i
      end

      it "should not send an email" do
        post :create, :email => "invalid-yo@test.com"
        ActionMailer::Base.deliveries = []
        ActionMailer::Base.deliveries.should be_empty
      end
    end #invalid

  end # psot create
end # spec
