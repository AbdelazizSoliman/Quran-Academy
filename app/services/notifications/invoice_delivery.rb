module Notifications
  class InvoiceDelivery
    CHANNELS = %w[email whatsapp].freeze

    def initialize(actor:, invoice:)
      @actor = actor
      @invoice = invoice
    end

    def call
      return [] unless @invoice.deliverable?

      CHANNELS.map do |channel|
        Dispatch.new(actor: @actor, recipient: @invoice.student_profile.user, source: @invoice,
                     type: "invoice_issued", channel:, primary_guardian: true,
                     idempotency_key: "invoice-issued:#{@invoice.id}:#{channel}:#{@invoice.updated_at.to_i}").call
      end
    end
  end
end
