require 'spec_helper'

require 'ostruct'

describe OAuthUser do

  describe '#logged_in?' do

    before(:each) do
      @email = 'joebob@what.com'
      @auth = OpenStruct.new provider: 'facebook', uid: '12345', info: {email: @email}
    end

    it 'returns true if user present' do
      user = OpenStruct.new name: 'Joe', email: @email
      o = OAuthUser.new(@auth, user)
      expect(o.logged_in?).to be_true
    end

    it 'returns false if no user present' do
      o = OAuthUser.new(@auth)
      expect(o.logged_in?).to be_false
    end

  end

  describe '#login_or_create' do

    context 'logged in' do
      before(:each) do
        @user = create(:user_with_facebook_authentication)
      end

      context 'authentication exists' do
        before(:each) do
          @auth = OpenStruct.new provider: 'facebook', uid: @user.authentications.first.uid, info: {email: @user.email}
        end

        it 'sets the user' do
          o = OAuthUser.new(@auth, @user)
          o.login_or_create
          expect(o.user).to eql(@user)
        end

        it 'does not add any authentications' do
          expect(Authentication.count).to eql(1)
          OAuthUser.new(@auth, @user).login_or_create
          expect(Authentication.count).to eql(1)
        end

        it 'does not add any users' do
          expect(User.count).to eql(1)
          OAuthUser.new(@auth, @user).login_or_create
          expect(User.count).to eql(1)
        end
      end

      context 'authentication does not exist' do
        before(:each) do
          @auth = OpenStruct.new provider: 'google', uid: '112233', info: {email: @user.email}
        end

        it 'creates an authentication for the logged in user' do
          expect(Authentication.count).to eql(1)
          OAuthUser.new(@auth, @user).login_or_create
          expect(Authentication.count).to eql(2)
          expect(Authentication.last.uid).to eql('112233')
          expect(Authentication.last.user).to eql(@user)
        end

        it 'does not add any users' do
          expect(User.count).to eql(1)
          OAuthUser.new(@auth, @user).login_or_create
          expect(User.count).to eql(1)
        end

        it "still works, even if the auth hash email is different" do
          expect(Authentication.count).to eql(1)
          another_email_auth_hash = OpenStruct.new provider: 'google', uid: '112233', info: {email: 'anotheremail@what.com'}
          OAuthUser.new(@auth, @user).login_or_create
          expect(Authentication.count).to eql(2)
          expect(Authentication.last.uid).to eql('112233')
          expect(Authentication.last.user).to eql(@user)
        end
      end
    end

    context 'logged out' do # nil (or nothing) passed in as user to OAuthUser.new
      context 'the oauth authentication matches an existing (provider/uid)' do
        before(:each) do
          @user = create(:user_with_facebook_authentication)
          @auth = OpenStruct.new provider: 'facebook', uid: @user.authentications.first.uid, info: {email: @user.email}
          @auth.stub(:slice).and_return({provider: @auth.provider, uid: @auth.uid })
        end

        it 'logs the user in attached to that authentication' do
          o = OAuthUser.new(@auth)
          o.login_or_create
          expect(o.user).to eql(@user)
        end

        it "does not create any authentications" do
          expect(Authentication.count).to eql(1)
          OAuthUser.new(@auth).login_or_create
          expect(Authentication.count).to eql(1)
        end

        it 'does not create any users' do
          expect(User.count).to eql(1)
          OAuthUser.new(@auth).login_or_create
          expect(User.count).to eql(1)
        end
      end

      context 'the oauth authentication does not match any existing' do
        context 'there is a user matching the policy incoming email' do
          before(:each) do
            @user = create(:user_with_facebook_authentication)
            @auth = OpenStruct.new provider: 'google', uid: '64999664', info: OpenStruct.new(email: @user.email)
            @auth.stub(:slice).and_return({provider: @auth.provider, uid: @auth.uid })
          end

          it "creates an authentication attached to user with matching email" do
            expect(Authentication.count).to eql(1)
            OAuthUser.new(@auth).login_or_create
            expect(Authentication.count).to eql(2)
            expect(Authentication.last.user).to eql(@user)
          end

          it 'does not create any users' do
            expect(User.count).to eql(1)
            OAuthUser.new(@auth).login_or_create
            expect(User.count).to eql(1)
          end
        end

        context 'there is no user matching the policy incoming email' do
          before(:each) do
            auth_email = 'abrandnewperson@what.com'
            @auth = OpenStruct.new provider: 'google', uid: '64999664', info: OpenStruct.new(email: auth_email, first_name: 'Joe', last_name: 'Smithton')
            @auth.stub(:slice).and_return({provider: @auth.provider, uid: @auth.uid })
          end

          it "creates a user" do
            expect(User.count).to eql(0)
            OAuthUser.new(@auth).login_or_create
            expect(User.count).to eql(1)
            expect(User.first.email).to eql(@auth.info.email)
          end

          it 'creates an authentication' do
            expect(Authentication.count).to eql(0)
            OAuthUser.new(@auth).login_or_create
            expect(Authentication.count).to eql(1)
            expect(Authentication.last.user.email).to eql(@auth.info.email)
          end
        end
      end
    end

  end

end
