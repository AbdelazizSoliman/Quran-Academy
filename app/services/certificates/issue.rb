module Certificates
  class Issue
    def initialize(actor:, attributes:)
      @actor = actor
      @attributes = attributes
    end

    def call
      certificate = Certificate.new(@attributes.merge(issuer: @actor))
      return forbidden(certificate) unless @actor.active? && @actor.admin?

      Certificate.transaction do
        certificate.save!
        certificate.events.create!(actor: @actor, event_type: "created",
                                   after_data: certificate.attributes.slice("certificate_type", "issued_on"))
      end
      certificate
    rescue ActiveRecord::RecordInvalid
      certificate
    end

    private

    def forbidden(certificate)
      certificate.errors.add(:base, :forbidden)
      certificate
    end
  end
end
