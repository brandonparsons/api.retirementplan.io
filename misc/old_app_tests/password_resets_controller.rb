require 'spec_helper'

describe PasswordResetsController do
  render_views

  before(:each) do
    activate_authlogic
  end

  describe "GET new" do

    it "should have the correct title" do
      get :new
      response.should be_success
      response.body.should have_selector("head title", :text => "Reset Password")
    end

    it "should only work if not logged in" do
      user = Factory.create(:user)
      sign_in(user)
      get :new
      flash[:info].should =~ /must be logged out/i
      response.should redirect_to dashboard_path
    end

    it "should render the 'new' page" do
      get :new
      response.should render_template('new')
    end

    it "should have a form to put in your email" do
      get :new
      response.body.should have_selector("form", :text => "Email")
    end

  end

  describe "POST create" do

    before(:each) do
      @valid_user = Factory.create(:user)
    end

    describe "successfully find the email" do

      before(:each) do
        ActionMailer::Base.deliveries = []
        post :create, :email => @valid_user.email
        ActionMailer::Base.deliveries.count.should == 1
      end

      it "should send an email" do
        ActionMailer::Base.deliveries.should_not be_empty
        ActionMailer::Base.deliveries.last.subject.should =~ /password reset instructions/i
      end

      it "should have the correct token in the email" do
        email = ActionMailer::Base.deliveries.last
        #message is now multipart, make sure both parts include perishable token
        token = User.find_by_email(@valid_user.email).perishable_token
        email.parts[0].body.to_s.should include token
        email.parts[1].body.to_s.should include token
      end

      it "should redirect to root with correct flash" do
        response.should redirect_to root_path
        flash[:info].should =~ /Sending password reset instructions to/i
      end

    end # success

    describe "post create" do

      it "should only work if not logged in" do
        sign_in(@valid_user)
        post :create, :email => @valid_user.email
        flash[:info].should =~ /must be logged out/i
        response.should redirect_to dashboard_path
      end
    end

    describe "can't find the email" do

      before(:each) do
        ActionMailer::Base.deliveries = []
        post :create, :email => "does-not-exist@example.com"
      end

      it "should not send an email" do
        ActionMailer::Base.deliveries.should be_empty
      end

      it "should re-render with correct flash" do
        response.should redirect_to root_path
      end

    end # can't find

  end # post create

  describe "GET edit" do

    before(:each) do
      @valid_user = Factory.create(:user)
      @token = @valid_user.perishable_token
    end

    describe "can find the user's perishable token" do

      it "should show the edit page with correct title" do
        get :edit, :id => @token
        response.should render_template :edit
        response.body.should have_selector("head title", :text => "Reset Password")
      end

      it "should have a form to allow the user to update their password" do
        get :edit, :id => @token
        response.body.should have_selector("form.formtastic.user")
        response.body.should have_selector("h1", :text => "Change My Password")
      end

    end # can find

    describe "can't find the user's perishable token" do

      it "should redirect to root with flash error" do
        get :edit, :id => 18 # obviously wrong
        response.should redirect_to root_path
        flash[:error].should =~ /we're sorry, but we could not locate your account/i
      end

    end # can't find

    describe "get edit" do

      it "should only work if not logged in" do
        sign_in(@valid_user)
        get :edit, :id => @token
        flash[:info].should =~ /must be logged out/i
        response.should redirect_to dashboard_path
      end
    end

  end # get edit

  describe "PUT update" do

    before(:each) do
      @valid_user = Factory.create(:user)
      @token = @valid_user.perishable_token
    end

    describe "can find the user's perishable token" do

      it "PUT update with valid password should be successful" do
        lambda do
          put :update, :id => @token, :user => { :name => @valid_user.name, :email => @valid_user.email, :password => "mynewpassword", :password_confirmation => "mynewpassword"}
          @valid_user.reload
        end.should change(@valid_user, :crypted_password)
      end

      it "should redirect to user's show page with correct flash and should be logged in" do
        put :update, :id => @token, :user => { :name => @valid_user.name, :email => @valid_user.email, :password => "mynewpassword", :password_confirmation => "mynewpassword"}
        response.should redirect_to dashboard_path
        flash[:success].should =~ /password successfully up/i
        signed_in?.should be_true
      end

      it "should not allow put update with invalid password" do
        lambda do
          put :update, :id => @token, :user => { :name => @valid_user.name, :email => @valid_user.email, :password => "invalid", :password_confirmation => ""}
          @valid_user.reload
        end.should_not change(@valid_user, :crypted_password)
      end

    end # can find

    describe "can't find the user's perishable token" do

      it "should redirect to root with flash error" do
        put :update, :id => 49, :user => { :name => @valid_user.name, :email => @valid_user.email, :password => "mynewpassword", :password_confirmation => "mynewpassword"}
        response.should redirect_to root_path
        flash[:error].should =~ /we're sorry, but we could not locate your account/i
      end

    end # can't find

    describe "put update" do

      it "should only work if not logged in" do
        sign_in(@valid_user)
        put :update, :id => @token, :user => { :name => @valid_user.name, :email => @valid_user.email, :password => "mynewpassword", :password_confirmation => "mynewpassword"}
        flash[:info].should =~ /must be logged out/i
        response.should redirect_to dashboard_path
      end
    end

  end # put update

end # spec
