class WhatsappMessage < ApplicationRecord
  DIRECTIONS = %w[inbound outbound].freeze

  belongs_to :whatsapp_conversation, inverse_of: :messages

  before_validation :generate_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\AWAM-[A-Z0-9]{10}\z/ }
  validates :provider_message_id, presence: true, uniqueness: true
  validates :direction, inclusion: { in: DIRECTIONS }
  validates :message_type, :received_at, presence: true
  validates :body, length: { maximum: 10_000 }, allow_blank: true

  scope :chronological, -> { order(received_at: :asc, id: :asc) }

  private

  def generate_public_id
    self.public_id ||= "WAM-#{SecureRandom.alphanumeric(10).upcase}"
  end
end
