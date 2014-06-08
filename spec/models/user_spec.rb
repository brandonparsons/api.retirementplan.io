require 'spec_helper'

describe User do

  describe "hstore properties" do
    it "responds to has_selected_expenses" do
      build_stubbed(:user).should respond_to(:has_selected_expenses)
      build_stubbed(:user).should respond_to(:has_selected_expenses?)
      build_stubbed(:user).should respond_to(:has_selected_expenses=)
    end

    it "responds to has_completed_simulation" do
      build_stubbed(:user).should respond_to(:has_completed_simulation)
      build_stubbed(:user).should respond_to(:has_completed_simulation?)
      build_stubbed(:user).should respond_to(:has_completed_simulation=)
    end

    it "responds to min_rebalance_spacing" do
      build_stubbed(:user).should respond_to(:min_rebalance_spacing)
      build_stubbed(:user).should respond_to(:min_rebalance_spacing=)
    end

    it "responds to max_contact_frequency" do
      build_stubbed(:user).should respond_to(:max_contact_frequency)
      build_stubbed(:user).should respond_to(:max_contact_frequency=)
    end

    it "responds to last_contact" do
      build_stubbed(:user).should respond_to(:last_contact)
      build_stubbed(:user).should respond_to(:last_contact=)
    end

    it "responds to allowable_drift" do
      build_stubbed(:user).should respond_to(:allowable_drift)
      build_stubbed(:user).should respond_to(:allowable_drift=)
    end

    it "responds to simulations_ran" do
      build_stubbed(:user).should respond_to(:simulations_ran)
      build_stubbed(:user).should respond_to(:simulations_ran=)
    end
  end

  describe "default preferences" do
    it "is created with default preferences" do
      Timecop.freeze do
        u = create(:user, name: nil)
        now = Time.zone.now

        expect(u.name).to eql('Me')
        expect(u.min_rebalance_spacing).to eql(90.days.to_i)
        expect(u.max_contact_frequency).to eql(7.days.to_i)
        expect(u.allowable_drift).to eql(5)
        expect(u.last_contact).to eql(now.to_i)
        expect(u.simulations_ran).to eql(0)
      end
    end

    it "does not automatically change on other saves" do
      u = create(:user)
      starting_time = u.last_contact.to_i

      u.min_rebalance_spacing = 50.days
      u.max_contact_frequency = 7.days
      u.allowable_drift       = 7
      u.last_contact          = 5.minutes.ago
      u.simulations_ran       = 20

      u.save

      expect(u.min_rebalance_spacing).not_to eql(90.days)
      expect(u.max_contact_frequency).not_to eql(7.days)
      expect(u.allowable_drift).not_to eql(5)
      expect(u.simulations_ran).not_to eql(0)
    end
  end

  describe "validations" do
    it "is valid from factory" do
      u = build(:user)
      u.should be_valid
    end

    it 'is not admin by default' do
      u = User.create! email: 'superdude@what.com'
      u.admin.should be_false
    end

    it "checks email for presence" do
      u = build(:user, email: nil)
        u.should_not be_valid
    end

    it "checks email for format" do
      u = build(:user, email: 'bob')
      u.should_not be_valid
    end

    it "checks email for uniqueness" do
      u = create(:user)
      u2 = build(:user, email: u.email)
      u2.should_not be_valid
    end

    it "checks min_rebalance_spacing" do
      u = create(:user)
      u.min_rebalance_spacing = -40.days
      u.should_not be_valid
    end

    it "checks max_contact_frequency" do
      u = create(:user)
      u.max_contact_frequency = -40.days
      u.should_not be_valid
    end

    it "checks allowable_drift" do
      u = create(:user)
      u.allowable_drift = -1
      u.should_not be_valid
    end

    describe "from_oauth" do
      it "true is valid" do
        u = build_stubbed(:user)
        u.should be_valid
        u.from_oauth = true
        u.should be_valid
      end

      it "false is valid" do
        u = build_stubbed(:user)
        u.should be_valid
        u.from_oauth = false
        u.should be_valid
      end

      it "something else is not valid" do
        u = build_stubbed(:user)
        u.should be_valid
        u.from_oauth = 123
        u.should be_valid
      end
    end
  end

  describe "::normalized_timestamp" do
    it "looks correct" do
      value = User.normalized_timestamp
      expect(value.is_a?(Integer)).to be_true
      expect(value).to be > 1402197669
      expect(value).to be < 2000000000
    end
  end

  describe "::with_tracked_portfolios" do
    it "grabs the correct users" do
      u1 = create(:user)
      p1 = create(:portfolio, user_id: u1.id)
      p1.tracking = true
      p1.save

      u2 = create(:user)
      p2 = create(:portfolio, user_id: u2.id)

      u3 = create(:user)
      p3 = create(:portfolio, user_id: u3.id)
      p3.tracking = true
      p3.save

      u4 = create(:user)
      p4 = create(:portfolio, user_id: u4.id)

      results = User.with_tracked_portfolios
      expect(results.length).to eql(2)
      ids = results.map(&:id)
      expect(ids).to include(u1.id)
      expect(ids).to include(u3.id)
    end
  end

  describe "::verifier_for" do
    it "returns a proper object" do
      expect( User.verifier_for('password-reset').is_a?(ActiveSupport::MessageVerifier) ).to be_true
    end
  end

  describe "#has_accepted_terms? && #accept_terms!" do
    it "is false to begin with" do
      u = create(:user)
      expect(u.has_accepted_terms?).to be_false
    end

    it "becomes true after accepting" do
      u = create(:user)
      u.accept_terms!
      expect(u.has_accepted_terms?).to be_true
    end
  end

  describe "has_questionnaire? && has_completed_questionnaire?" do
    before(:each) { @user = create(:user) }

    it "both false with no questionnaire" do
      @user.has_questionnaire?.should be_false
      @user.has_completed_questionnaire?.should be_false
    end

    it "both true with a questionnaire" do
      questionnaire = create(:questionnaire, user_id: @user.id)
      @user.has_questionnaire?.should be_true
      @user.has_completed_questionnaire?.should be_true
    end

    it "has_questionnaire? if built" do
      @user.build_questionnaire
      @user.has_questionnaire?.should be_true
    end
  end

  describe "#is_male?" do
    before(:each) { @user = create(:user) }

    it "raises error if they havent completed the questionnaire" do
      expect { @user.is_male? }.to raise_error
    end

    it "returns true if male" do
      questionnaire = create(:questionnaire, user_id: @user.id, sex: 1)
      expect(@user.is_male?).to be_true
    end

    it "returns false if not male" do
      questionnaire = create(:questionnaire, user_id: @user.id, sex: 0)
      expect(@user.is_male?).to be_false
    end
  end

  describe "#is_married?" do
    before(:each) { @user = create(:user) }

    it "raises error if they havent completed the questionnaire" do
      expect { @user.is_married? }.to raise_error
    end

    it "returns true if married" do
      questionnaire = create(:questionnaire, user_id: @user.id, married: 1)
      expect(@user.is_married?).to be_true
    end

    it "returns false if not married" do
      questionnaire = create(:questionnaire, user_id: @user.id, married: 0)
      expect(@user.is_married?).to be_false
    end
  end

  describe "#age" do
    before(:each) { @user = create(:user) }

    it "raises error if they havent completed the questionnaire" do
      expect { @user.age }.to raise_error
    end

    it "returns the users age" do
      questionnaire = create(:questionnaire, user_id: @user.id, age: 55)
      expect(@user.age).to eql(55)
    end
  end

  describe "#has_selected_portfolio?" do
    it "is false if no selected_port" do
      u = build_stubbed(:user)
      expect(u.has_selected_portfolio?).to be_false
    end

    it "is true once they've selected one" do
      u = build_stubbed(:user)
      p = create(:portfolio, user_id: u.id)
      expect(u.has_selected_portfolio?).to be_true
    end

  end

  describe "#allowable_securities" do
    it "doesnt return keys if no selected_portfolio" do
      u = build_stubbed(:user)
      expect(u.allowable_securities).to be_false
    end

    it "returns the selected port keys if available" do
      require 'ostruct'
      u = build_stubbed(:user)
      port = OpenStruct.new weights: {
        "EEM" => 0.5,
        "VDMIX" => 0.5
      }
      u.stub(:portfolio).and_return(port)
      expect(u.allowable_securities).to eql(["EEM", "VDMIX"])
    end
  end

  describe "#has_selected_expenses!" do
    it "sets to true" do
      u = create(:user)
      expect(u.has_selected_expenses?).to be_false
      u.has_selected_expenses!
      expect(u.has_selected_expenses?).to be_true
    end
  end

  describe "#has_defined_simulation_parameters?" do
    before(:each) do
      @u = create(:user)
    end

    it "returns false if no params" do
      expect(@u.has_defined_simulation_parameters?).to be_false
    end

    it "returns true if params" do
      p = create(:retirement_simulation_parameters, user: @u)
      expect(@u.has_defined_simulation_parameters?).to be_true
    end
  end

  describe "#has_completed_simulation!" do
    it "sets to true" do
      u = create(:user)
      expect(u.has_completed_simulation?).to be_false
      u.has_completed_simulation!
      expect(u.has_completed_simulation?).to be_true
    end
  end

  describe "#has_setup_tracked_portfolio?" do
    it "returns false if no portfolio" do
      u = create(:user)
      expect(u.has_setup_tracked_portfolio?).to be_false
    end

    it "returns false if have just selected a portfolio" do
      u = create(:user)
      p = build_stubbed(:portfolio, user: u)
      expect(u.has_setup_tracked_portfolio?).to be_false
    end

    it "returns true if portfolio is being tracked" do
      u = create(:user)
      p = build_stubbed(:portfolio, user: u)
      p.stub(:tracking?).and_return(true)
      expect(u.has_setup_tracked_portfolio?).to be_true
    end
  end

  describe '#send_etf_purchase_instructions' do
    it "delivers an email" do
      ActionMailer::Base.deliveries = []
      u = build_stubbed(:user)
      expect{u.send_etf_purchase_instructions(10000)}.to change{Sidekiq::Extensions::DelayedMailer.jobs.size}.by(1)
      Sidekiq::Extensions::DelayedMailer.drain
      expect(ActionMailer::Base.deliveries.length).to eql(1)
    end
  end

  describe "#check_portfolio_balance" do
    it "is ok to mock the portfolio behaviour" do
      Portfolio.new.should respond_to(:out_of_balance?)
    end

    before(:each) do
      @u = build_stubbed(:user)
    end

    context "portfolio out of balance" do
      before(:each) do
        @u.stub(:portfolio_out_of_balance?).and_return(true)
      end

      it "sends email if appropriate time between contacts" do
        @u.stub(:can_contact?).and_return(true)
        @u.should_receive(:send_out_of_balance_email)
        @u.should_not_receive(:send_min_rebalance_spacing_email)
        @u.check_portfolio_balance
        # Actual email send is tested below (private method)
      end

      it "doesnt send email if too short between contacts" do
        @u.stub(:can_contact?).and_return(false)
        @u.should_not_receive(:send_out_of_balance_email)
        @u.should_not_receive(:send_min_rebalance_spacing_email)
        @u.check_portfolio_balance
      end
    end

    context "Portfolio in balance" do
      before(:each) do
        @u.stub(:portfolio_out_of_balance?).and_return(false)
      end

      it "sends email if appropriate time between contacts" do
        @u.stub(:exceeded_max_rebalance_frequency).and_return(true)
        @u.should_receive(:send_min_rebalance_spacing_email)
        @u.should_not_receive(:send_out_of_balance_email)
        @u.check_portfolio_balance
        # Actual email send is tested below (private method)
      end

      it "doesnt send email if too short between contacts" do
        @u.stub(:exceeded_max_rebalance_frequency).and_return(false)
        @u.should_not_receive(:send_min_rebalance_spacing_email)
        @u.should_not_receive(:send_out_of_balance_email)
        @u.check_portfolio_balance
      end
    end
  end

  describe "#ran_simulations!" do
    it "adds to the number of simulations ran, when starting from zero" do
      u = create(:user)
      expect(u.simulations_ran).to eql(0)
      expect(u.ran_simulations!(20)).to be_true
      expect(u.simulations_ran).to eql(20)
    end

    it "can start from other values too" do
      u = create(:user)
      u.simulations_ran = 20; u.save;
      expect(u.simulations_ran).to eql(20)
      expect(u.ran_simulations!(20)).to be_true
      expect(u.simulations_ran).to eql(40)
    end

    it "returns false if invalid value passed" do
      u = create(:user)
      expect(u.ran_simulations!("asdf")).to be_false
    end

    it "returns false if invalid value passed" do
      u = create(:user)
      expect(u.ran_simulations!("20x")).to be_false
    end

    it "returns false if invalid value passed" do
      u = create(:user)
      expect(u.ran_simulations!("x20")).to be_false
    end
  end

  describe "#confirm && #confirm! && #confirmed?" do
    it "is not confirmed by default" do
      u = create(:user)
      expect(u.confirmed?).to be_false
    end

    it "becomes confirmed once confirmed!" do
      # This also tests #confirm
      u = create(:user)
      u.confirm!
      expect(u.confirmed?).to be_true
    end
  end

  describe "#is_confirmed_or_temporarily_allowed?" do
    it "returns true if the user is confirmed" do
      u = create(:user, :confirmed)
      expect(u.is_confirmed_or_temporarily_allowed?).to be_true
    end

    it "returns true if the user is not confirmed, but fresh" do
      u = create(:user)
      expect(u.is_confirmed_or_temporarily_allowed?).to be_true
    end

    it "returns false if hte user is not confirmed, and not fresh" do
      u = create(:user)
      Timecop.freeze(Date.today + 30) do
        expect(u.is_confirmed_or_temporarily_allowed?).to be_false
      end
    end
  end

  describe "#sign_in!" do
    it "needs tests" do
      pending
    end
    it "tests for image set if provided" do
      pending
    end
    it "tests for image gravatar if nil" do
      pending
    end
  end

  describe "#session_data" do
    it "needs tests" do
      pending
    end
  end

  describe "#sign_out!" do
    it "needs tests" do
      pending
    end
  end

  describe "#has_password?" do
    it "needs tests" do
      pending
    end
  end

  describe "#confirm_email_token" do
    it "needs tests" do
      pending
    end
  end

  describe "TokenAuthenticable" do
    it "needs tests" do
      pending
    end
  end

  describe "-- private methods we're still going to test --" do

    describe "#can_contact?" do
      it "returns true if has been long enough" do
        u = create(:user)
        u.last_contact = 5.days.ago
        u.max_contact_frequency = 7.days
        u.save

        expect(u.send(:can_contact?)).to be_false
      end

      it "returns false if not long enough" do
        u = create(:user)
        u.last_contact = 12.days.ago
        u.max_contact_frequency = 7.days
        u.save

        expect(u.send(:can_contact?)).to be_true
      end
    end

    describe "#contact!" do
      it "sets last_contact to now" do
        u = create(:user)
        u.last_contact = 5.days.ago
        u.save

        Timecop.freeze do
          now = Time.zone.now
          u.send(:contact!)
          expect(u.last_contact).to eql(now.to_i)
        end
      end
    end

    describe "#exceeded_max_rebalance_frequency" do
      it "returns true if has been long enough" do
        u = create(:user)
        u.last_contact = 5.days.ago
        u.min_rebalance_spacing = 90.days
        u.save

        expect(u.send(:exceeded_max_rebalance_frequency)).to be_false
      end

      it "returns false if not long enough" do
        u = create(:user)
        u.last_contact = 95.days.ago
        u.min_rebalance_spacing = 90.days
        u.save

        expect(u.send(:exceeded_max_rebalance_frequency)).to be_true
      end
    end

    describe "#portfolio_out_of_balance?" do
      # This is quite a bit of repetition from tracked_portfolio_spec, but was
      # having some issues with the method so want to make sure working 100%

      before(:each) do
        @u = create(:user)
        @u.allowable_drift = 7
        @u.save

        @p = @u.build_portfolio(weights: {
          "BWX"   => 0.30,
          "EEM"   => 0.35,
          "VDMIX" => 0.35
        })

        @p.selected_etfs = {
          "BWX"   => "BWZ",
          "EEM"   => "SCHE",
          "VDMIX" => "VDMIX"
        }

        @p.current_shares = {
          "BWZ"   => 300,
          "SCHE"  => 350,
          "VDMIX" => 350
        }
        @p.save
      end

      it "returns false if false" do
        Finance::Quotes.should_receive(:for_etfs).with(["BWZ", "SCHE", "VDMIX"]).and_return({
          "BWZ"   => 100,
          "SCHE"  => 100,
          "VDMIX" => 100
        })

        expect(@u.send :portfolio_out_of_balance?).to be_false
      end

      it "returns false if false - within allowable_drift" do
        Finance::Quotes.should_receive(:for_etfs).and_return({
          "BWZ"   => 130, # Works out to < 7% off
          "SCHE"  => 100,
          "VDMIX" => 100
        })

        expect(@u.send :portfolio_out_of_balance?).to be_false
      end

      it "returns true if true" do
        Finance::Quotes.should_receive(:for_etfs).with(["BWZ", "SCHE", "VDMIX"]).and_return({
          "BWZ"   => 150,
          "SCHE"  => 100,
          "VDMIX" => 100
        })

        expect(@u.send :portfolio_out_of_balance?).to be_true
      end
    end

    describe "send_out_of_balance_email" do
      it "creates a job" do
        ActionMailer::Base.deliveries = []
        u = build_stubbed(:user)
        expect{u.send(:send_out_of_balance_email)}.to change{Sidekiq::Extensions::DelayedMailer.jobs.size}.by(1)
        Sidekiq::Extensions::DelayedMailer.drain
        expect(ActionMailer::Base.deliveries.length).to eql(1)
      end

      it "resets contact time" do
        u = create(:user)
        Timecop.freeze do
          u.should_receive(:contact!)
          u.send(:send_out_of_balance_email)
          expect(u.last_contact).to eql(Time.zone.now.to_i)
        end
      end
    end

    describe "send_min_rebalance_spacing_email" do
      it "creates a job" do
        ActionMailer::Base.deliveries = []
        u = build_stubbed(:user)
        expect{u.send(:send_min_rebalance_spacing_email)}.to change{Sidekiq::Extensions::DelayedMailer.jobs.size}.by(1)
        Sidekiq::Extensions::DelayedMailer.drain
        expect(ActionMailer::Base.deliveries.length).to eql(1)
      end

      it "resets contact time" do
        u = create(:user)
        Timecop.freeze do
          u.should_receive(:contact!)
          u.send(:send_min_rebalance_spacing_email)
          expect(u.last_contact).to eql(Time.zone.now.to_i)
        end
      end
    end

    describe "#etf_purchase_instructions email" do
      it "needs tests" do
        pending
        # ActionMailer::Base.deliveries = []
        # # Stuff
        # Sidekiq::Extensions::DelayedMailer.drain
        # expect(ActionMailer::Base.deliveries.length).to eql(1)
      end
    end

  end

end
