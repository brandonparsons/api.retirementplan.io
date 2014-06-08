require 'spec_helper'

describe RegularUser do

  it 'is not admin by default' do
    u = RegularUser.create! email: 'superdude@what.com', name: 'Superman', password: 'asdfasdf', password_confirmation: 'asdfasdf'
    u.admin.should be_false
  end

  it "is not from_oauth" do
    pending
  end

  it "finds only users with password_digest by default" do
    pending
  end

  describe "validations" do
    describe "password" do
      it "is required on create" do
        pending
      end
      it "is not required on update" do
        pending
      end
      it "must be minimum 6 characters when provided" do
        pending
      end
    end
  end

  describe "::find_from_all_users_with_email" do
    it "finds from all users, even if doesn't have password_digest" do
      pending
    end
  end

  describe "::find_from_all_users_with_id" do
    it "finds from all users, even if doesn't have password_digest" do
      pending
    end
  end

  describe "#password_reset_token" do
    it "has tests" do
      pending
    end
  end

end
