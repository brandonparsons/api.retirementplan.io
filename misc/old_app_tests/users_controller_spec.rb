require 'spec_helper'

describe UsersController do
  render_views

  before(:each) do
    activate_authlogic
  end

  describe "dashboard stuff" do

    it "should properly assign the action-complete and action-incomplete classes to divs" do
      pending
    end

    it "should properly stick buttons into the wells based on what is complete" do
      pending
    end

    it "should properly assign text into the quick-hits div with appropriate next step MAKE SURE TO TEST BOTH STANDARD PLAN AND BASIC PLAN USERS" do
      pending
    end

    it "should show the complete checkmark buttons or the 'x' if not done on the dashboard page" do
      pending
    end

  end

  describe "password changes" do

    describe "GET changepassword" do

      before(:each) do
        @valid_user = Factory.create(:user)
        sign_in(@valid_user)
      end

      it "should respond to the action, correct title" do
        get :change_password
        response.should be_success
        response.body.should have_selector("head title", :text => "Change Password")
      end

      it "should render the correct information" do
        get :change_password
        response.should render_template("users/change_password")
        response.body.should have_selector("form.formtastic.user")
      end

      it "should only work if logged in" do
        sign_out
        get :change_password
        flash[:error].should =~ /must be logged in/i
        response.should redirect_to login_path
      end
    end

    describe "PUT changepassword" do

      before(:each) do
        @valid_user = Factory.create(:user)
        sign_in(@valid_user)
      end

      it "should not work unless you put in the current password" do
        put :update_password, :user => { :name => @valid_user.name, :email => @valid_user.email, :current_password => "wrong", :password => "mynewpassword", :password_confirmation => "mynewpassword"}
        flash[:error].should =~ /please correctly enter your current/i
      end

      it "should succeed and redirect to correct location on valid attributes" do
        put :update_password, :user => { :name => @valid_user.name, :email => @valid_user.email, :current_password => "foobar", :password => "mynewpassword", :password_confirmation => "mynewpassword"}
        flash[:success].should =~ /password successfully upd/i
        response.should redirect_to dashboard_path
        assigns[:user].should == @valid_user
      end

      it "should change the password on valid attributes" do
        lambda do
          put :update_password, :user => { :name => @valid_user.name, :email => @valid_user.email, :current_password => "foobar", :password => "mynewpassword", :password_confirmation => "mynewpassword"}
          @valid_user.reload
        end.should change(@valid_user, :crypted_password)
      end

      it "should not work with invalid attributes" do
        put :update_password, :user => { :name => @valid_user.name, :email => @valid_user.email, :password => "invalid", :password_confirmation => "asdf"}
        flash[:success].should be_nil
        response.should render_template("users/change_password")
        response.body.should have_selector("span.help-inline")
      end

      it "should not work when trying to change another user's password" do
        another_user = Factory.create(:user)
        lambda do
          put :update_password, :user => { :name => another_user.name, :email => another_user.email, :current_password => "foobar", :password => "mynewpassword", :password_confirmation => "mynewpassword"}
        end.should_not change(another_user, :password)
      end

      it "should only work if logged in" do
        sign_out
        put :update_password, :user => { :name => @valid_user.name, :email => @valid_user.email, :current_password => "foobar", :password => "mynewpassword", :password_confirmation => "mynewpassword"}
        flash[:error].should =~ /must be logged in/i
        response.should redirect_to login_path
      end

    end
  end

  describe "GET 'new'" do

    it "should be successful" do
      get :new
      response.should be_success
      response.body.should have_selector('title', :text => "Sign Up")
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

    it "should have a signup form" do
      get :new
      response.body.should have_selector("form.formtastic.user")
    end

  end

  describe "POST 'create'" do

    describe "failure" do

      before(:each) do
        @attr = Factory.attributes_for(:invalid_user)
      end

      it "should not create a user" do
        lambda do
          post :create, :user => @attr
        end.should_not change(User, :count)
      end

      it "should render the 'new' page" do
        post :create, :user => @attr
        response.should render_template('new')
        response.body.should have_selector("span.help-inline")
      end

      it "should have the right title" do
        post :create, :user => @attr
        response.body.should have_selector('title', :text => "Sign Up")
      end

      it "should only create a user if not logged in" do
        @another_user = Factory.create(:user)
        sign_in(@another_user)
        @valid_attr = Factory.attributes_for(:user)
        post :create, :user => @attr
        flash[:info].should =~ /must be logged out/i
        response.should redirect_to dashboard_path
      end

    end #failure

    describe "success" do

      before(:each) do
        @attr = Factory.attributes_for(:user)
      end

      it "should create a user" do
        lambda do
          post :create, :user => @attr
        end.should change(User, :count).by(1)
      end

      it "should redirect to the user root page, letting them know they should verify" do
        post :create, :user => @attr
        assigns[:user].email.should == @attr[:email]
        response.should redirect_to signup_complete_path
      end

      it "should have a note that verification is required" do
        post :create, :user => @attr
        flash[:info].should =~ /Verification e-mail queued - should arrive in the next 5 minutes./i
      end

      it "should deliver the verification email" do
        #@observer = UserObserver.instance
        ActionMailer::Base.deliveries = []
        lambda {
          post :create, :user => @attr
        }.should change(ActionMailer::Base.deliveries, :size).by(2) # user verification and admin notification
      end

      it "should have the correct info in the email" do
        #@observer = UserObserver.instance
        ActionMailer::Base.deliveries = []
        post :create, :user => @attr
        user_delivery = ActionMailer::Base.deliveries[-2]
        user_delivery.to.should include @attr[:email]
        user_delivery.subject.should =~ /verification instructions/i
        #message is now multipart, make sure both parts include the name
        user_delivery.parts[0].body.to_s.should include @attr[:name]
        user_delivery.parts[1].body.to_s.should include @attr[:name]
        #message is now multipart, make sure both parts include perishable token
        token = User.find_by_email(@attr[:email]).perishable_token
        user_delivery.parts[0].body.to_s.should include token
        user_delivery.parts[1].body.to_s.should include token

        admin_delivery = ActionMailer::Base.deliveries.last
        admin_delivery.to.should include "brandon@easyretirementplanning.ca"
        admin_delivery.subject.should =~ /new user signup/i
      end

      it "queues two mails when a user is created" do
        ActionMailer::Base.deliveries = []
        #@observer = UserObserver.instance
        post :create, :user => @attr
        ActionMailer::Base.deliveries.count.should == 2
      end

      it "should not be logged in" do
        post :create, :user => @attr
        UserSession.find.should be_nil
      end

      it "should not be an admin user" do
        post :create, :user => @attr
        new_user = User.find_by_email(@attr[:email])
        new_user.new_record?.should be_false
        new_user.admin?.should be_false
      end

      it "should not be verified by default" do
        post :create, :user => @attr
        new_user = User.find_by_email(@attr[:email])
        new_user.new_record?.should be_false
        new_user.verified?.should be_false
      end

    end #success
  end # post create

  describe "GET edit" do

    before(:each) do
      @valid_user = Factory.create(:user)
      sign_in(@valid_user)
    end

    describe "success" do

      it "should get edit if logged in" do
        get :edit, :id => @valid_user
        response.should be_success
      end

      it "should have the right title" do
        get :edit, :id => @valid_user
        response.body.should have_selector("head title", :text => "Edit User")
      end

      it "should render the 'edit' page" do
        get :edit, :id => @valid_user
        response.should render_template('edit')
      end

      it "should have an edit form" do
        get :edit, :id => @valid_user
        response.body.should have_selector("form.formtastic.user")
      end

    end # success

    describe "failure" do

      it "should not get edit if logged out" do
        sign_out
        get :edit, :id => @valid_user
        flash[:error].should =~ /must be logged in/i
        response.should redirect_to(login_path)
      end
    end # failure

    describe "fiddling with other users" do

      it "should not allow  you to edit another user" do
        another_user = Factory.create(:user)
        get :edit, :id => another_user.id
        #puts response.body
        response.body.should have_selector("input#user_name", :value => @valid_user.email)
      end

      it "as an admin you shouldn't be able to edit other user" do
        sign_out
        admin_user = Factory.create(:admin_user)
        sign_in(admin_user)
        get :edit, :id => @valid_user.id

        # You should be redirected to home (as it is trying to edit the admin page)
        response.should redirect_to root_path
      end

    end
  end # GET edit

  describe "GET show" do

    before(:each) do
      @valid_user = Factory.create(:user)
      sign_in(@valid_user)
    end

    describe "success" do

      it "should get show if logged in" do
        get :show
        response.should be_success
      end

      it "should have the right title" do
        get :show
        response.body.should have_selector("head title", :text => "Profile for #{@valid_user.name}")
      end

      it "should render the 'show' page" do
        get :show
        response.should render_template('show')
      end

      it "should have a link to edit" do
        get :show
        response.body.should have_link("Edit", :href => edit_user_path)
      end

    end # success

    describe "failure" do

      it "should not get show if logged out" do
        sign_out
        get :show
        flash[:error].should =~ /must be logged in/i
        response.should redirect_to login_path
      end

      it "should only be able to see their own page" do
        @another_user = Factory.create(:user)
        get :show, :id => @another_user
        response.should redirect_to root_path
        # assigns[:user].should == @valid_user
        # flash[:error].should =~ /attempt logged/i
      end

    end # failure

    describe "admin users" do

      before(:each) do
        @admin_user = Factory.create(:admin_user)
        sign_out
        sign_in(@admin_user)
      end

      it "should get their own show page if that is the selection" do
        get :show, :id => @admin_user
        response.body.should have_selector("head title", :text => "Profile for #{@admin_user.name}")
      end

      it "should work as profile path as well" do
        get :show
        response.body.should have_selector("head title", :text => "Profile for #{@admin_user.name}")
      end

      it "should also be able to get other people's show page if that is the selection" do
        get :show, :id => @valid_user
        response.body.should have_selector("head title", :text => "Profile for #{@valid_user.name}")
      end

      it "should not show admin content on admin login" do
        sign_in(@valid_user)
        get :show, :id => @valid_user
        response.body.should_not have_link("Show Users", :href => users_path)
      end

    end

  end # GET show

  describe "PUT update" do

    before(:each) do
      @valid_user = Factory.create(:user)
      sign_in(@valid_user)
    end

    describe "success" do

      before(:each) do
        @new_attrs = { :name => "new name", :email => "myname@gmail.com", :password => @valid_user.password, :password_confirmation => @valid_user.password}
      end

      it "should correctly update the user with valid attributes" do
        put :update, :id => @valid_user.id, :user => @new_attrs
        assigns[:user].name.should == "new name"
        assigns[:user].email.should == "myname@gmail.com"
        User.find(@valid_user.id).email.should == "myname@gmail.com"
      end

      it "should redirect to the user show page" do
        put :update, :id => @valid_user.id, :user => @new_attrs
        response.should redirect_to profile_path
        flash[:success].should =~ /edited/i
      end

    end # success

    describe "failure" do

      before(:each) do
        @bad_attrs = { :name => "", :email => "nottaken"}
      end

      it "should not update user attributes if invalid" do
        original_email = @valid_user.email
        put :update, :id => @valid_user, :user => @bad_attrs
        @valid_user.reload
        @valid_user.email.should == original_email
        signed_in?.should be_true
        User.find_by_email(original_email).should_not be_nil
      end

      it "should re-render the edit page" do
        put :update, :id => @valid_user, :user => @bad_attrs
        #controller.stub!(:require_user).and_return(true)
        response.should render_template('edit')
        signed_in?.should be_true
      end

      it "should not allow edit, even with valid attributes, if not logged in" do
        sign_out
        original_email = @valid_user.email
        put :update, :id => @valid_user, :user => @new_attrs
        @valid_user.reload
        @valid_user.email.should == original_email
        response.should redirect_to login_path
        signed_in?.should be_false
      end

      it "should not allow you to take another user's email" do
        @another_user = Factory.create(:user)
        put :update, :id => @valid_user, :user => { :name => "valid name", :email => @another_user.email}
        response.should render_template('edit')
        response.body.should have_selector("span.help-inline")
      end

    end #failure

  end # post update

  describe "DELETE destroy" do

    before(:each) do
       @valid_user = Factory.create(:user)
    end

    describe "as a non-signed-in user" do
      it "should deny access" do
        delete :destroy, :id => @valid_user
        flash[:error].should =~ /must be logged in/i
        response.should redirect_to login_path
      end
    end

    describe "as a non-admin user" do
      it "should allow user to delete themselves" do
        sign_in(@valid_user)
        delete :destroy, :id => @valid_user
        response.should redirect_to(root_path)
        flash[:success].should =~ /Your account has been destroyed/i
      end

      it "should not allow someone to delete another user" do
        pending
      end
    end

    describe "as an admin user" do

      before(:each) do
        @admin = Factory(:admin_user)
        sign_in(@admin)
      end

      it "should not destroy the user (only allowing via console)" do
        lambda do
          delete :destroy, :id => @valid_user
        end.should_not change(User, :count)
      end

      it "should redirect to the users page with the correct flash" do
        delete :destroy, :id => @valid_user
        response.should redirect_to(root_path)
        flash[:warn].should =~ /Can't edit admin details from web interface/i
        # flash[:success].should =~ /account has been destroyed/i
      end

    end
  end
end #spec
