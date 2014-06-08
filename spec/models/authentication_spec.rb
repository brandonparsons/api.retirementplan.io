require 'spec_helper'

describe Authentication do
  describe "Validations" do
    describe "UID/Provider" do
      it "does not allow the same UID on a given provider" do
        a = create(:authentication, :facebook)
        b = Authentication.new(provider: 'facebook', uid: a.uid)
        b.should_not be_valid
      end
      it "does allow the same UID on different providers" do
        a = create(:authentication, :facebook)
        b = Authentication.new(provider: 'google', uid: a.uid)
        b.should be_valid
      end
    end
  end
end
