class WhatsappConversation < ApplicationRecord
  STATUSES = %w[open archived].freeze

  belongs_to :contact, polymorphic: true, optional: true
  has_many :messages, class_name: "WhatsappMessage", dependent: :restrict_with_exception

  before_validation :generate_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\AWAC-[A-Z0-9]{10}\z/ }
  validates :sender_phone, presence: true, uniqueness: true,
                           format: { with: /\A\+[1-9]\d{7,14}\z/ }
  validates :status, inclusion: { in: STATUSES }
  validates :unread_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :last_message_at, presence: true

  scope :recent_first, -> { order(last_message_at: :desc, id: :desc) }
  scope :unread, -> { where("unread_count > 0") }

  def display_name
    contact_name || sender_name.presence || sender_phone
  end

  def mark_read!
    update!(unread_count: 0, read_at: Time.current) if unread_count.positive?
  end

  private

  def contact_name
    return contact.display_name if contact.respond_to?(:display_name)
    return contact.full_name if contact.respond_to?(:full_name)

    contact.user.full_name if contact.respond_to?(:user) && contact.user
  end

  def generate_public_id
    self.public_id ||= "WAC-#{SecureRandom.alphanumeric(10).upcase}"
  end
end
