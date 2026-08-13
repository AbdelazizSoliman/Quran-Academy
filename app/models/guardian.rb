class Guardian < ApplicationRecord
  GENDERS = StudentProfile::GENDERS
  STATUSES = %w[active inactive archived].freeze
  CONTACT_METHODS = %w[email phone whatsapp].freeze
  LANGUAGES = %w[ar en].freeze

  belongs_to :created_by, class_name: "User", optional: true, inverse_of: :created_guardians
  belongs_to :updated_by, class_name: "User", optional: true, inverse_of: :updated_guardians
  belongs_to :user, optional: true, inverse_of: :guardian_profile
  has_many :student_guardianships, dependent: :restrict_with_exception
  has_many :student_profiles, through: :student_guardianships
  has_many :events, class_name: "GuardianEvent", dependent: :restrict_with_exception
  has_many :communication_logs, dependent: :restrict_with_exception
  has_many :received_notifications, class_name: "Notification", foreign_key: :recipient_guardian_id,
                                    dependent: :restrict_with_exception

  attr_readonly :public_id
  before_validation :normalize_values
  before_validation :generate_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\AGRD-[A-Z0-9]{10}\z/ }
  validates :full_name, presence: true, length: { maximum: 150 }
  validates :gender, inclusion: { in: GENDERS }
  validates :status, inclusion: { in: STATUSES }
  validates :preferred_contact_method, inclusion: { in: CONTACT_METHODS }
  validates :preferred_language, inclusion: { in: LANGUAGES }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone_number, :whatsapp_number, length: { maximum: 30 }, allow_blank: true
  validates :user_id, uniqueness: true, allow_nil: true
  validates :internal_notes, length: { maximum: 5_000 }, allow_blank: true
  validate :active_has_contact
  validate :preferred_contact_available
  validate :user_must_be_guardian

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  def usable_contact?
    email.present? || phone_number.present? || whatsapp_number.present?
  end

  def archived?
    status == "archived"
  end

  private

  def normalize_values
    self.email = email.to_s.strip.downcase.presence
    %i[phone_number whatsapp_number].each { |field| self[field] = self[field].to_s.strip.presence }
    self.preferred_language = preferred_language.to_s.downcase
  end

  def generate_public_id
    self.public_id ||= "GRD-#{SecureRandom.alphanumeric(10).upcase}"
  end

  def active_has_contact
    errors.add(:base, :contact_required) if status == "active" && !usable_contact?
  end

  def preferred_contact_available
    required = { "email" => email, "phone" => phone_number, "whatsapp" => whatsapp_number }[preferred_contact_method]
    return unless preferred_contact_method.present? && required.blank?

    errors.add(preferred_contact_method,
               :required_for_preference)
  end

  def user_must_be_guardian
    errors.add(:user, :must_be_guardian) if user && !user.guardian?
  end
end
