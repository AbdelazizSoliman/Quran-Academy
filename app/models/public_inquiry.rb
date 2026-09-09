class PublicInquiry < ApplicationRecord
  TYPES = %w[trial contact].freeze
  STATUSES = %w[new contacted qualified closed spam].freeze
  LOCALES = %w[ar en].freeze
  SOURCE = "public_website".freeze
  PUBLIC_ID_PATTERN = /\ALEAD-[A-Z0-9]{12}\z/

  attr_accessor :website

  belongs_to :handled_by, class_name: "User", optional: true

  before_validation :normalize_fields
  before_validation :apply_submission_defaults, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: PUBLIC_ID_PATTERN }
  validates :inquiry_type, inclusion: { in: TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :preferred_locale, inclusion: { in: LOCALES }
  validates :source, inclusion: { in: [SOURCE] }
  validates :name, presence: true, length: { maximum: 150 }
  validates :phone, :whatsapp_number, length: { maximum: 20 }, allow_blank: true
  validates :email, length: { maximum: 254 }, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :student_age, numericality: { only_integer: true, in: 1..120 }, allow_nil: true
  validates :preferred_schedule_notes, :message, :internal_notes, length: { maximum: 2_000 }, allow_blank: true
  validates :subject, length: { maximum: 200 }, allow_blank: true
  validate :contact_method_present
  validate :contact_message_present
  validate :phone_numbers_are_valid

  scope :recent_first, -> { order(submitted_at: :desc, id: :desc) }

  TYPES.each { |value| define_method(:"#{value}?") { inquiry_type == value } }

  private

  def normalize_fields
    @invalid_phone_fields = []
    %i[name email subject preferred_schedule_notes message internal_notes].each do |field|
      self[field] = self[field].to_s.strip.presence
    end
    self.email = email&.downcase
    normalize_phone(:phone)
    normalize_phone(:whatsapp_number)
  end

  def normalize_phone(field)
    value = self[field].to_s.strip
    return self[field] = nil if value.blank?

    result = Notifications::E164Normalizer.call(value)
    if result.valid?
      self[field] = result.e164
    else
      (@invalid_phone_fields ||= []) << field
      self[field] = value
    end
  end

  def apply_submission_defaults
    self.public_id ||= "LEAD-#{SecureRandom.alphanumeric(12).upcase}"
    self.status ||= "new"
    self.source ||= SOURCE
    self.submitted_at ||= Time.current
  end

  def contact_method_present
    present = trial? ? phone.present? || whatsapp_number.present? : phone.present? || email.present?
    errors.add(:base, :contact_method_required) unless present
  end

  def contact_message_present
    errors.add(:message, :blank) if contact? && message.blank?
  end

  def phone_numbers_are_valid
    Array(@invalid_phone_fields).each { |field| errors.add(field, :invalid) }
  end
end
