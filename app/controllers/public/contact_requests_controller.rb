module Public
  class ContactRequestsController < InquiriesController
    def new = new_inquiry("contact")
    def create = submit_inquiry("contact")
  end
end
