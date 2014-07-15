require 'base64'

module V1

  class PortfoliosController < SecuredController
    before_action :ensure_user_completed_questionnaire!
    before_action :ensure_user_selected_portfolio!,   only: [:show]
    before_action :ensure_user_completed_simulation!, only: [:show]


    ##########################
    # SELECT PORTFOLIO PHASE #
    ##########################

    def index
      if params[:ids] && params[:ids].present?
        # Purposefully getting an array, rather than current_user.portfolio
        portfolios = Portfolio.where(id: params[:ids], user_id: current_user.id)
        render json: portfolios if stale?(etag: portfolios)
      else # Standard index action (no IDS array parameter)
        if last_modified = current_user.portfolio.try(:updated_at)
          # Purposefully getting an array, rather than current_user.portfolio
          render json: Portfolio.where(user_id: current_user.id) if stale?(etag: last_modified, last_modified: last_modified)
        else
          render json: {portfolios: []}
        end
      end
    end

    # This is called by the FrontierPortfolio plain Ember Object / controller
    # to map the user's current portfolio to the select_portfolio charts.
    def selected_for_frontier
      response = {}
      if portfolio = current_user.portfolio
        # Need to keep rails from encoding as strings b/c of BigDecimals....
        json = FloatMapper.call(portfolio.weights).to_json
        response[:id] = Base64.urlsafe_encode64(json)
      end
      render json: response
    end

    # This is called from the FrontierPortfolio/select_portfolio object/routes
    # when the user picks a portfolio from select_portfolio.
    def create
      return missing_parameters unless params[:allocation]

      current_portfolio = current_user.portfolio
      new_portfolio = current_user.build_portfolio(weights: params[:allocation])

      # FIXME: This shouldn't be required once using Python-Securities
      if current_portfolio
        new_portfolio.current_shares = current_portfolio.current_shares
        new_portfolio.selected_etfs = current_portfolio.selected_etfs
      end

      if new_portfolio.save
        render json: {success: true, message: "Saved your portfolio selection."}
      else
        render json: new_portfolio.errors, status: :unprocessable_entity
      end
    end


    ###########################
    # TRACKED PORTFOLIO PHASE #
    ###########################

    # This is called by the Portfolio DS.Model
    def show
      portfolio = current_user.portfolio
      render json: portfolio if stale?(portfolio)
    end

  end

end
