class Notification < ApplicationRecord
  CHANNELS = %w[email whatsapp].freeze
  TYPES = %w[account_invitation lesson_pre_reminder lesson_late_reminder lesson_reminder late_reminder
             lesson_cancelled lesson_rescheduled
             lesson_report certificate].freeze
  STATUSES = %w[pending sending sent delivered failed].freeze
  SOURCES = %w[AccountInvitation ScheduledLesson LessonReport Certificate].freeze
  PROVIDERS = %w[resend meta_whatsapp].freeze

  belongs_to :recipient_user, class_name: "User", inverse_of: :received_notifications
  belongs_to :actor, class_name: "User", inverse_of: :sent_notifications
  belongs_to :source, polymorphic: true, optional: true
  belongs_to :recipient_guardian, class_name: "Guardian", optional: true
  has_many :events, class_name: "NotificationEvent", dependent: :restrict_with_exception
  has_many :attempts, class_name: "NotificationAttempt", dependent: :restrict_with_exception

  attr_readonly :public_id, :recipient_user_id, :recipient_guardian_id, :actor_id, :source_type, :source_id, :channel,
                :notification_type, :provider, :recipient_address_masked, :recipient_locale, :subject,
                :message_snapshot, :delivery_payload_ciphertext, :idempotency_key, :scheduled_at, :queued_at
  before_validation :generate_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\ANOT-[A-Z0-9]{10}\z/ }
  validates :channel, inclusion: { in: CHANNELS }
  validates :notification_type, inclusion: { in: TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :source_type, inclusion: { in: SOURCES }, allow_nil: true
  validates :provider, inclusion: { in: PROVIDERS }
  validates :recipient_locale, inclusion: { in: %w[ar en] }
  validates :recipient_address_masked, :message_snapshot, presence: true
  validates :idempotency_key, uniqueness: true, allow_nil: true
  validates :attempt_count, :retry_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :http_status, numericality: { only_integer: true, in: 100..599 }, allow_nil: true

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
  STATUSES.each { |value| define_method(:"#{value}?") { status == value } }
  CHANNELS.each { |value| define_method(:"#{value}?") { channel == value } }

  private

  def generate_public_id = self.public_id ||= "NOT-#{SecureRandom.alphanumeric(10).upcase}"
end
