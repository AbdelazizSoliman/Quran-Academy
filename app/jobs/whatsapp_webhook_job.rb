class WhatsappWebhookJob < ApplicationJob
  queue_as :default
  self.log_arguments = false

  retry_on ActiveRecord::Deadlocked, wait: :polynomially_longer, attempts: 5
  retry_on ActiveRecord::ConnectionNotEstablished, wait: :polynomially_longer, attempts: 5

  def perform(payload)
    Whatsapp::IngestWebhook.new(payload:).call
  end
end
