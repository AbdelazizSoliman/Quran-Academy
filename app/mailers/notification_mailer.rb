class NotificationMailer < ApplicationMailer
  def delivery
    @body = params.fetch(:body)
    mail(to: params.fetch(:recipient), subject: params.fetch(:subject))
  end
end
