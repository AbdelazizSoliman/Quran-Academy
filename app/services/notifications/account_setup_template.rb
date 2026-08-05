module Notifications
  class AccountSetupTemplate
    def self.call(display_name:, email:, url_suffix:,
                  name: ENV.fetch("WHATSAPP_ACCOUNT_SETUP_TEMPLATE", "quran_account_setup"),
                  language: ENV.fetch("WHATSAPP_ACCOUNT_SETUP_LANGUAGE", "en_US"))
      body = { type: "body", parameters: text_parameters(display_name, email) }
      button = { type: "button", sub_type: "url", index: "0",
                 parameters: [{ type: "text", text: url_suffix }] }
      {
        name:, language_code: language,
        components: [body, button]
      }
    end

    def self.text_parameters(display_name, email)
      [{ type: "text", text: display_name }, { type: "text", text: email }]
    end

    private_class_method :text_parameters
  end
end
