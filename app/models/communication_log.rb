class CommunicationLog < ApplicationRecord
  CHANNELS = %w[whatsapp email].freeze
  TEMPLATE_TYPES = %w[lesson_summary student_progress guardian_progress homework absence_notice lateness_notice
                      missed_lesson_follow_up custom].freeze
  STATUSES = %w[prepared opened confirmed_sent cancelled failed].freeze

  belongs_to :scheduled_lesson, optional: true
  belongs_to :lesson_report, optional: true
  belongs_to :lesson_student_report, optional: true
  belongs_to :student_profile, optional: true
  belongs_to :guardian, optional: true
  belongs_to :recipient_user, class_name: "User", optional: true
  belongs_to :actor, class_name: "User"
  belongs_to :confirmed_by, class_name: "User", optional: true
  has_many :events, class_name: "CommunicationLogEvent", inverse_of: :communication_log,
                    dependent: :restrict_with_exception

  attr_readonly :public_id, :scheduled_lesson_id, :lesson_report_id, :lesson_student_report_id,
                :student_profile_id, :guardian_id, :recipient_user_id, :actor_id, :channel, :template_type,
                :recipient_address_masked, :recipient_locale, :message_snapshot, :subject_snapshot
  before_validation :generate_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\ACOM-[A-Z0-9]{10}\z/ }
  validates :channel, inclusion: { in: CHANNELS }
  validates :template_type, inclusion: { in: TEMPLATE_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :recipient_locale, inclusion: { in: %w[ar en] }
  validates :message_snapshot, :recipient_address_masked, :prepared_at, presence: true

  scope :recent_first, -> { order(prepared_at: :desc, id: :desc) }

  STATUSES.each { |value| define_method(:"#{value}?") { status == value } }

  private

  def generate_public_id
    self.public_id ||= "COM-#{SecureRandom.alphanumeric(10).upcase}"
  end
end
