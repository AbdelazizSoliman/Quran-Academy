module Admin
  class FinanceLedgerEntriesController < BaseController
    def index
      scope = FinanceLedgerEntry.includes(:source, :actor).recent_first
      scope = scope.where(currency: params[:currency]) if StudentProfile::CURRENCIES.include?(params[:currency])
      @pagy, @entries = pagy(:offset, scope, limit: 50)
    end
  end
end
