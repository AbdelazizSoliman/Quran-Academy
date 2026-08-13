class FeePlan < ApplicationRecord
  BILLING_CYCLES = %w[per_lesson weekly monthly package].freeze
  CURRENCY_PATTERN = /\A[A-Z]{3}\z/
  CURRENCY_SYMBOLS = { "EGP" => "ج.م", "USD" => "$", "SAR" => "ر.س", "AED" => "د.إ" }.freeze

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

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name, :id) }

  def currency_symbol = CURRENCY_SYMBOLS.fetch(currency, currency)

  private

  def normalize_values
    self.currency = currency.to_s.strip.upcase
  end

  def generate_public_id
    self.public_id ||= "FEE-#{SecureRandom.alphanumeric(10).upcase}"
  end
end
