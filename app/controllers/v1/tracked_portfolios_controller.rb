module V1

  class TrackedPortfoliosController < SecuredController
    before_action :ensure_user_completed_questionnaire!,
      :ensure_user_selected_portfolio!, :ensure_user_completed_simulation!

    def quotes
      # Need to return quotes for all relevant securities - rebalancing calc on
      # client side needs both current shares (even if not in current target
      # allocation), and all target ETFs.
      render json: QuotesService.for_etfs(current_user.portfolio.tickers_for_quotes)
    end

    def create
      return missing_parameters unless
        params[:selected_etfs] && params[:current_shares]

      return invalid_parameters unless
        params[:selected_etfs].is_a?(Hash) && params[:current_shares].is_a?(Hash)

      portfolio = current_user.portfolio

      portfolio.selected_etfs   = params[:selected_etfs]
      portfolio.current_shares  = params[:current_shares]

      if portfolio.save
        render json: portfolio
      else
        render json: portfolio.errors, status: :unprocessable_entity
      end
    end

    def purchased_units
      return missing_parameters unless params[:purchased_units]
      return invalid_parameters unless params[:purchased_units].is_a?(Hash)

      portfolio = current_user.portfolio

      portfolio.apply_transaction params[:purchased_units]
      portfolio.tracking = true

      if portfolio.save
        render json: {success: true, message: 'Transaction is reflected in your tracked portfolio.'}
      else
        render json: portfolio.errors, status: :unprocessable_entity
      end
    end

    def email_instructions
      return missing_parameters unless params[:email_information] && params[:amount]
      current_user.send_etf_purchase_instructions(params[:amount], params[:email_information])
      render json: {success: true, message: 'Email is being sent.'}
    end

  end

end
