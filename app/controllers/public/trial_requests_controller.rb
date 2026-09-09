module Public
  class TrialRequestsController < InquiriesController
    def new = new_inquiry("trial")
    def create = submit_inquiry("trial")
  end
end
