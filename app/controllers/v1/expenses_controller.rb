module V1

  class ExpensesController < SecuredController
    before_action :ensure_user_completed_questionnaire!
    before_action :ensure_user_selected_portfolio!

    def index
      current_user_expenses = current_user.expenses

      if params[:ids] && params[:ids].present? # Ember data will apparently hit index action with ids array
        @expenses = current_user_expenses.where(id: params[:ids])
        render json: @expenses if stale?(etag: @expenses)
      else # Standard index action (no IDS array parameter)
        last_modified = current_user_expenses.maximum(:updated_at)
        render json: current_user_expenses if stale?(etag: last_modified, last_modified: last_modified)
      end
    end

    def create
      expense = current_user.expenses.build(expense_params)
      if expense.save
        render json: expense, status: :created
      else
        render json: expense.errors, status: :unprocessable_entity
      end
    end

    def show
      expense = current_user.expenses.find(params[:id])
      render json: expense if stale?(expense)
    end

    def update
      expense = current_user.expenses.find(params[:id])
      if expense.update_attributes(expense_params)
        render json: expense, status: :ok
      else
        render json: expense.errors, status: :unprocessable_entity
      end
    end

    def destroy
      expense = current_user.expenses.find(params[:id])
      expense.destroy
      render json: nil, status: :ok
    end

    def confirm
      current_user.has_selected_expenses!
      render json: current_user # Relying on this to be the current user in `parameters.js` route (beforeModel save pushPayload)
    end


    private

    def expense_params
      # Working with UTC integers on the client to simplify date handling. Convert
      # here to Ruby/Rails dates, otherwise ActiveRecord won't save it.

      new_params      = cleaned_params
      ends_utc        = new_params[:ends]
      onetime_on_utc  = new_params[:onetime_on]

      new_params[:ends]       = Time.zone.at(ends_utc) if ends_utc.present?
      new_params[:onetime_on] = Time.zone.at(onetime_on_utc) if onetime_on_utc.present?

      return new_params
    end

    def cleaned_params
      params.require(:expense).permit(:description, :amount, :frequency, :ends,
        :onetime_on, :notes, :is_added)
    end

  end

end
