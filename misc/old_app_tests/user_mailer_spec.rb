require "spec_helper"

describe UserMailer do

  before(:each) do
    ActionMailer::Base.deliveries = []
    @user = Factory.create(:user)
  end

  describe "out of balance emails" do
    it "should should test the out of balance emails" do
      pending
    end
  end

  describe "verification emails" do

    before(:each) do
      UserMailer.verification_instructions(@user).deliver
      ActionMailer::Base.deliveries.should_not be_empty
      @email = ActionMailer::Base.deliveries.last
    end

    it "should be set to be delivered to the email passed in" do
      @email.should deliver_to(@user.email)
    end

    it "should contain the user's name in the mail body" do
      @email.should have_body_text(/#{@user.name}/i)
    end

    it "should contain the correct message" do
      @email.should have_body_text(/verify your e-mail address/i)
      @email.should have_body_text(/Click here/i)
    end

    it "should contain a link to the confirmation link" do
      @email.should have_body_text(/user_verifications/)
    end

    it "should have the correct subject" do
      @email.should have_subject(/verification instructions/i)
    end

    it "should be from the right person" do
      @email.from.should == ["admin@easyretirementplanning.ca"]
    end

  end

  describe "password reset emails" do

    before(:each) do
      UserMailer.password_reset_instructions(@user).deliver
      ActionMailer::Base.deliveries.should_not be_empty
      @email = ActionMailer::Base.deliveries.last
    end

    it "should be set to be delivered to the email passed in" do
      @email.should deliver_to(@user.email)
    end

    it "should contain the correct message" do
      @email.should have_body_text(/a request to reset your password has been made/i)
    end

    it "should contain a link to the confirmation link" do
      @email.should have_body_text(/password_reset/)
    end

    it "should have the correct subject" do
      @email.should have_subject(/password reset instructions/i)
    end

    it "should be from the right person" do
      @email.from.should == ["admin@easyretirementplanning.ca"]
    end

  end

  describe "admin signup notify" do

    before(:each) do
      UserMailer.admin_notification_signup(@user).deliver
      ActionMailer::Base.deliveries.should_not be_empty
      @email = ActionMailer::Base.deliveries.last
    end

    it "should be set to be delivered to the email passed in" do
      @email.should deliver_to("brandon@easyretirementplanning.ca")
    end

    it "should contain the correct message" do
      @email.should have_body_text(/New User Signup!/i)
    end

    it "should contain a link to the user's profile link" do
      @email.should have_body_text(/\/users\/#{@user.id}/)
    end

    it "should have the correct subject" do
      @email.should have_subject(/new user signup/i)
    end

    it "should be from the right person" do
      @email.from.should == ["admin@easyretirementplanning.ca"]
    end

  end

  describe "admin mailing list notify" do

    before(:each) do
      UserMailer.mailing_list_admin_notification(@user.email).deliver
      ActionMailer::Base.deliveries.should_not be_empty
      @email = ActionMailer::Base.deliveries.last
    end

    it "should be set to be delivered to the email passed in" do
      @email.should deliver_to("brandon@easyretirementplanning.ca")
    end

    it "should contain the correct message" do
      @email.should have_body_text(/Mailing List Signup/i)
    end

    it "should have the correct subject" do
      @email.should have_subject(/Mailing List Signup/i)
    end

    it "should be from the right person" do
      @email.from.should == ["admin@easyretirementplanning.ca"]
    end

  end

  describe "ETF email" do

    before(:each) do
      response = {"VCE.TO"=>165295, "VDMIX"=>30639, "VFISX"=>95360}
      UserMailer.etf_purchasing_instructions(@user,response).deliver
      ActionMailer::Base.deliveries.should_not be_empty
      @email = ActionMailer::Base.deliveries.last
    end

    it "should be set to be delivered to the email passed in" do
      @email.should deliver_to(@user.email)
    end

    it "should contain the correct message" do
      @email.should have_body_text(/ETF Purchasing Instructions/i)
    end

    it "should contain a link to the user's dashboard" do
      @email.should have_body_text(/\/dashboard/)
    end

    it "should have the correct subject" do
      @email.should have_subject(/ETF Purchasing Instructions/i)
    end

    it "should be from the right person" do
      @email.from.should == ["admin@easyretirementplanning.ca"]
    end

    it "should have the correct stuff in it" do
      @email.should have_body_text(/VCE.TO/i)
      @email.should have_body_text(/95360/i)
    end

  end

end
