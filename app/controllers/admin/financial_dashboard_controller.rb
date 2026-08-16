module Admin
  class FinancialDashboardController < SchedulingBaseController
    def show
      @dashboard = Admin::FinancialDashboardQuery.new(month: params[:month]).call
    end
  end
end
