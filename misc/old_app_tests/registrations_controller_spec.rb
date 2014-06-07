require 'spec_helper'

describe Users::RegistrationsController do

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "PUT update" do

    context 'logged out' do
      it 'cant be accessed' do
        put :update, user: { name: 'smithbob', current_password: 'asdfasdf'}
        expect(response.body).to include('/users/sign_in')
      end
    end

    context 'logged in' do
      before(:each) do
        @user = create(:user, :confirmed)
        sign_in @user
      end

      it 'only allows update of current user' do
        another_user = create(:user, :confirmed)
        another_user_original_name = another_user.name

        my_original_name = @user.name

        new_name = "JoeBobSmith"
        put :update, id: another_user, user: { name: new_name, current_password: 'asdfasdf'}
        @user.reload
        another_user.reload
        expect(@user.name).to eql(new_name)
        expect(another_user.name).to eql(another_user_original_name)
      end

      context 'regular user (email/password)' do

        context 'without current_password' do
          before(:each) do
            @attrs = {}
          end

          it 'wont allow password update' do
            new_password = "asdfasdfas"
            put :update, user: @attrs.merge({password: new_password, password_confirmation: new_password})
            @user.reload
            expect(@user.valid_password?(new_password)).to be_false
            expect(@user.valid_password?('asdfasdf')).to be_true
          end

          it 'wont allow name update' do
            new_name = "JoeBobSmith"
            original_name = @user.name
            put :update, user: @attrs.merge({name: new_name})
            @user.reload
            expect(@user.name).to eql(original_name)
          end

          it 'does not update email (reconfirmable or not)' do
            original_email = @user.email
            new_email = "Smithton@what.com"
            put :update, user: @attrs.merge({email: new_email})
            @user.reload
            expect(@user.email).to eql(original_email)
            expect(@user.unconfirmed_email).to be_nil
          end
        end

        context 'with current_password' do
          before(:each) do
            @attrs = {current_password: 'asdfasdf'}
          end

          it 'allows password update' do
            new_password = "asdfasdfas"
            put :update, user: @attrs.merge({password: new_password, password_confirmation: new_password})
            @user.reload
            expect(@user.valid_password?(new_password)).to be_true
          end

          it 'allows name update' do
            new_name = "JoeBobSmith"
            put :update, user: @attrs.merge({name: new_name})
            @user.reload
            expect(@user.name).to eql(new_name)
          end

          it 'does not update email - reconfirmable' do
            original_email = @user.email
            new_email = "Smithton@what.com"
            put :update, user: @attrs.merge({email: new_email})
            @user.reload
            expect(@user.email).to eql(original_email)
            expect(@user.unconfirmed_email).to eql(new_email)
          end

        end

      end

      context 'OAuth user' do
        before(:each) do
          @user = create(:user_with_facebook_account, :confirmed, :from_oauth)
          sign_in @user
        end

        it 'allows a name update without current password' do
          new_name = "JoeBobSmith"
          put :update, user: { name: new_name }
          @user.reload
          expect(@user.name).to eql(new_name)
        end

        it 'does not allow email update' do
          original_email = @user.email
          new_email = "Smithton@what.com"
          put :update, user: { email: new_email, name: @user.name } # Need to tack on a name param, otherwise it blows away the entire user param hash
          @user.reload
          expect(@user.email).to eql(original_email)
          expect(@user.unconfirmed_email).to be_nil
        end

        it 'does not allow a password update' do
          new_password = "asdfasdfas"
          put :update, user: { password: new_password, password_confirmation: new_password, name: @user.name }
          @user.reload
          expect(@user.valid_password?(new_password)).to be_false
        end
      end
    end

  end

end
