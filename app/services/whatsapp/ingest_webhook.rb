module Whatsapp
  class IngestWebhook
    MESSAGE_BODY_PATHS = {
      "text" => %w[text body], "button" => %w[button text], "image" => %w[image caption],
      "document" => %w[document caption]
    }.freeze

    def initialize(payload:)
      @payload = payload
    end

    def call
      message_values.each { |value| ingest_value(value) }
    end

    private

    def message_values
      return [] unless @payload["object"] == "whatsapp_business_account"

      Array(@payload["entry"]).flat_map { |entry| Array(entry["changes"]) }
                              .select { |change| change["field"] == "messages" }
                              .pluck("value")
    end

    def ingest_value(value)
      validate_phone_number_id!(value)
      contacts = Array(value["contacts"]).index_by { |contact| contact["wa_id"] }
      Array(value["messages"]).each { |message| ingest_message(message, contacts[message["from"]]) }
    end

    def validate_phone_number_id!(value)
      expected = ENV.fetch("WHATSAPP_PHONE_NUMBER_ID", nil)
      received = value.dig("metadata", "phone_number_id")
      raise SecurityError, "Unexpected WhatsApp phone number ID" if expected.present? && received != expected
    end

    def ingest_message(message, contact_data)
      return if message["id"].blank? || WhatsappMessage.exists?(provider_message_id: message["id"])

      phone = Notifications::E164Normalizer.call(message["from"])
      return unless phone.valid?

      WhatsappConversation.transaction do
        conversation = conversation_for(phone.e164, contact_data, message)
        create_message!(conversation, message)
      end
    rescue ActiveRecord::RecordNotUnique
      nil
    end

    def conversation_for(phone, contact_data, message)
      conversation = WhatsappConversation.lock.find_or_initialize_by(sender_phone: phone)
      conversation.assign_attributes(sender_name: contact_data&.dig("profile", "name").presence ||
                                                   conversation.sender_name,
                                     contact: conversation.contact || ContactMatcher.call(phone),
                                     last_message_at: received_at(message), status: "open",
                                     unread_count: conversation.unread_count + 1)
      conversation.save!
      conversation
    end

    def create_message!(conversation, message)
      conversation.messages.create!(provider_message_id: message["id"], message_type: message["type"],
                                    body: message_body(message), received_at: received_at(message),
                                    metadata: safe_metadata(message))
    end

    def received_at(message)
      Time.zone.at(Integer(message["timestamp"], 10))
    rescue ArgumentError, TypeError
      Time.current
    end

    def message_body(message)
      return interactive_body(message) if message["type"] == "interactive"

      path = MESSAGE_BODY_PATHS[message["type"]]
      body = message.dig(*path) if path
      body || message.dig("document", "filename")
    end

    def interactive_body(message)
      message.dig("interactive", "button_reply", "title") ||
        message.dig("interactive", "list_reply", "title")
    end

    def safe_metadata(message)
      media = message[message["type"]]
      { "media_id" => media&.dig("id"), "mime_type" => media&.dig("mime_type") }.compact
    end
  end
end
