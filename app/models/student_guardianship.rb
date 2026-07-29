class StudentGuardianship < ApplicationRecord
  RELATIONSHIP_TYPES = %w[
    father mother stepfather stepmother grandfather grandmother brother sister
    uncle aunt legal_guardian sponsor other
  ].freeze
  STATUSES = %w[active inactive ended].freeze

  belongs_to :student_profile
  belongs_to :guardian
  belongs_to :created_by, class_name: "User", optional: true, inverse_of: :created_student_guardianships
  belongs_to :updated_by, class_name: "User", optional: true, inverse_of: :updated_student_guardianships
  has_many :events, class_name: "StudentGuardianshipEvent", dependent: :restrict_with_exception

  before_validation :normalize_values

  validates :relationship_type, inclusion: { in: RELATIONSHIP_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :custom_relationship, presence: true, if: -> { relationship_type == "other" }
  validates :guardian_id, uniqueness: {
    scope: %i[student_profile_id relationship_type],
    conditions: -> { where(status: "active") },
    message: :duplicate_active_relationship
  }
  validate :date_order
  validate :ended_date
  validate :active_date

  scope :active, -> { where(status: "active") }
  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  def active?
    status == "active"
  end

  private

  def normalize_values
    self.custom_relationship = nil unless relationship_type == "other"
  end

  def date_order
    errors.add(:ends_on, :before_starts_on) if ends_on && starts_on && ends_on < starts_on
  end

  def ended_date
    errors.add(:ends_on, :required_for_ended) if status == "ended" && ends_on.blank?
  end

  def active_date
    errors.add(:ends_on, :not_allowed_for_active) if status == "active" && ends_on&.<(Date.current)
  end
end
