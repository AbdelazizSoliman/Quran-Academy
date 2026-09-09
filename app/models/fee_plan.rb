class FeePlan < ApplicationRecord
  include PubliclyPublishable

  BILLING_CYCLES = %w[per_lesson weekly monthly package].freeze
  CURRENCY_PATTERN = /\A[A-Z]{3}\z/
  CURRENCY_SYMBOLS = { "EGP" => "ج.م", "USD" => "$", "SAR" => "ر.س", "AED" => "د.إ" }.freeze
  # Public pages never fall back to the other language, so both locales must be complete
  # before a fee plan can be published.
  PUBLIC_REQUIRED_FIELDS = %i[name_ar name_en].freeze
  MAX_PUBLIC_FEATURES = 8

  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"
  has_many :student_profiles, inverse_of: :fee_plan, dependent: :nullify

  attr_readonly :public_id
  before_validation :normalize_values
  before_validation :generate_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\AFEE-[A-Z0-9]{10}\z/ }
  validates :name, presence: true, length: { maximum: 200 }
  validates :amount, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1_000_000 }
  validates :currency, format: { with: CURRENCY_PATTERN }
  validates :billing_cycle, inclusion: { in: BILLING_CYCLES }
  validates :tax_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :invoice_day, numericality: { only_integer: true, in: 1..31 }
  validates :name_ar, :name_en, :price_note_ar, :price_note_en,
            :public_cta_label_ar, :public_cta_label_en, length: { maximum: 200 }, allow_blank: true
  validates :description_ar, :description_en, :public_features_ar, :public_features_en,
            length: { maximum: 2_000 }, allow_blank: true
  validates :public_display_order, numericality: { only_integer: true, in: 0..100_000 }
  validate :public_content_rules, if: :published?

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name, :id) }
  # Publication requires both an operational `active` flag and an explicit `published` flag,
  # so activating a fee plan never makes it public on its own.
  scope :publicly_visible, -> { where(active: true, published: true) }

  def currency_symbol = CURRENCY_SYMBOLS.fetch(currency, currency)
  def publicly_visible? = active? && published?

  def public_features(locale)
    value = locale.to_s == "ar" ? public_features_ar : public_features_en
    value.to_s.split("\n").map(&:strip).compact_blank.first(MAX_PUBLIC_FEATURES)
  end

  private

  def normalize_values
    self.currency = currency.to_s.strip.upcase
  end

  def public_content_rules
    PUBLIC_REQUIRED_FIELDS.each do |field|
      errors.add(field, :public_content_required) if public_send(field).blank?
    end
  end

  def generate_public_id
    self.public_id ||= "FEE-#{SecureRandom.alphanumeric(10).upcase}"
  end
end
