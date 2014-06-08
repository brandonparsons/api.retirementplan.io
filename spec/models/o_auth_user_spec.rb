require 'spec_helper'

describe OAuthUser do

  describe '#logged_in?' do

    before(:each) do
      @email  = 'joebob@what.com'
      @auth   = {
        'provider'  => 'facebook',
        'uid'       => '12345',
        'email'     => @email
      }
    end

    it 'returns true if user present' do
      user = build_stubbed(:user)
      o = OAuthUser.new(@auth, user)
      expect(o.logged_in?).to be_true
    end

    it 'returns false if no user present' do
      o = OAuthUser.new(@auth, nil)
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
          @auth   = {
            'provider'  => 'facebook',
            'uid'       => @user.authentications.first.uid,
            'email'     => @user.email
          }
        end

        it 'sets the user' do
          o = OAuthUser.new(@auth, @user)
          o.login_or_create
          expect(o.instance_variable_get "@user").to eql(@user)
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

        it 'returns the user, and false to `user_was_created`' do
          user, user_was_created = OAuthUser.new(@auth, @user).login_or_create
          expect(user).to eql(@user)
          expect(user_was_created).to be_false
        end
      end

      context 'authentication does not exist' do
        before(:each) do
          @auth   = {
            'provider'  => 'google',
            'uid'       => '112233',
            'email'     => @user.email
          }
        end

        it 'creates an authentication for the logged in user' do
          expect(Authentication.count).to eql(1)
          OAuthUser.new(@auth, @user).login_or_create
          expect(Authentication.count).to eql(2)
          expect(Authentication.order(created_at: :asc).last.uid).to eql('112233')
          expect(Authentication.last.user).to eql(@user)
        end

        it 'does not add any users' do
          expect(User.count).to eql(1)
          OAuthUser.new(@auth, @user).login_or_create
          expect(User.count).to eql(1)
        end

        it 'returns the user, and false to `user_was_created`' do
          user, user_was_created = OAuthUser.new(@auth, @user).login_or_create
          expect(user).to eql(@user)
          expect(user_was_created).to be_false
        end

        it "still works, even if the auth hash email is different" do
          expect(Authentication.count).to eql(1)
          another_email_auth_hash = { 'provider' => 'google', 'uid' => '112233', 'email' => 'anotheremail@what.com' }
          OAuthUser.new(@auth, @user).login_or_create
          expect(Authentication.count).to eql(2)
          expect(Authentication.order(created_at: :asc).last.uid).to eql('112233')
          expect(Authentication.order(created_at: :asc).last.user).to eql(@user)
        end

        it "raises a custom error if the authentication is invalid" do
          create(:authentication, uid: '112233', provider: 'google')
          invalid_auth = {
            'provider'  => 'google',
            'uid'       => '112233',
            'email'     => @user.email
          }
          expect {
            OAuthUser.new(@auth, @user).login_or_create
          }.to raise_error(CustomExceptions::ErrorSavingAuthentication)
        end
      end
    end

    context 'logged out' do # nil (or nothing) passed in as user to OAuthUser.new
      context 'the oauth authentication matches an existing (provider/uid)' do
        before(:each) do
          @user = create(:user_with_facebook_authentication)
          @auth   = {
            'provider'  => 'facebook',
            'uid'       => @user.authentications.first.uid,
            'email'     => @user.email
          }
        end

        it 'logs the user in attached to that authentication' do
          o = OAuthUser.new(@auth, nil)
          o.login_or_create
          expect(o.instance_variable_get "@user").to eql(@user)
        end

        it "does not create any authentications" do
          expect(Authentication.count).to eql(1)
          OAuthUser.new(@auth, nil).login_or_create
          expect(Authentication.count).to eql(1)
        end

        it 'does not create any users' do
          expect(User.count).to eql(1)
          OAuthUser.new(@auth, nil).login_or_create
          expect(User.count).to eql(1)
        end

        it 'returns the user, and false to `user_was_created`' do
          user, user_was_created = OAuthUser.new(@auth, @user).login_or_create
          expect(user).to eql(@user)
          expect(user_was_created).to be_false
        end
      end

      context 'the oauth authentication does not match any existing' do
        context 'there is an oauth user matching the incoming email' do
          before(:each) do
            @user = create(:user_with_facebook_authentication, :from_oauth)
            @auth   = {
              'provider'  => 'google',
              'uid'       => '64999664',
              'email'     => @user.email
            }
          end

          it "raises a custom exception" do
            # We want them to log in first
            expect {
              OAuthUser.new(@auth, nil).login_or_create
            }.to raise_error(CustomExceptions::UserExistsFromOauth)
          end
        end

        context 'there is a non-oauth user matching the incoming email' do
          before(:each) do
            @user = create(:user)
            @auth   = {
              'provider'  => 'google',
              'uid'       => '64999664',
              'email'     => @user.email
            }
          end

          it "raises a custom exception" do
            # We want them to log in first
            expect {
              OAuthUser.new(@auth, nil).login_or_create
            }.to raise_error(CustomExceptions::UserExistsWithPassword)
          end
        end

        context 'there is a non-oauth user (even with another auth provider) matching the incoming email' do
          before(:each) do
            @user = create(:user_with_facebook_authentication)
            @auth   = {
              'provider'  => 'google',
              'uid'       => '64999664',
              'email'     => @user.email
            }
          end
          it "raises a custom exception" do
            # We want them to log in first
            expect {
              OAuthUser.new(@auth, nil).login_or_create
            }.to raise_error(CustomExceptions::UserExistsWithPassword)
          end
        end

        context 'there is no user matching the incoming email' do
          before(:each) do
            auth_email = 'abrandnewperson@what.com'
            @auth   = {
              'provider'  => 'google',
              'uid'       => '64999664',
              'email'     => auth_email,
              'name'      => 'Bobert'
            }
          end

          it "creates a user" do
            expect(User.count).to eql(0)
            OAuthUser.new(@auth, nil).login_or_create
            expect(User.count).to eql(1)
            expect(User.first.email).to eql(@auth['email'])
          end

          it 'creates an authentication' do
            expect(Authentication.count).to eql(0)
            OAuthUser.new(@auth, nil).login_or_create
            expect(Authentication.count).to eql(1)
            expect(Authentication.last.user.email).to eql(@auth['email'])
          end

          it 'returns the user, and true to `user_was_created`' do
            user, user_was_created = OAuthUser.new(@auth, @user).login_or_create
            expect(user.email).to eql(@auth['email'])
            expect(user_was_created).to be_true
          end
        end
      end
    end

  end

end
