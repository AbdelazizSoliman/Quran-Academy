class FinancePayment < ApplicationRecord
  STATUSES = %w[completed refunded].freeze
  METHODS = %w[cash bank_transfer card wallet other].freeze

  belongs_to :finance_invoice
  belongs_to :recorded_by, class_name: "User"
  belongs_to :refunded_by, class_name: "User", optional: true
  has_many :ledger_entries, as: :source, class_name: "FinanceLedgerEntry", dependent: :restrict_with_exception

  attr_readonly :public_id, :finance_invoice_id, :amount, :currency, :received_on, :payment_method, :recorded_by_id
  before_validation :generate_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\APMT-[A-Z0-9]{10}\z/ }
  validates :status, inclusion: { in: STATUSES }
  validates :payment_method, inclusion: { in: METHODS }
  validates :currency, inclusion: { in: StudentProfile::CURRENCIES }
  validates :amount, numericality: { greater_than: 0 }
  validates :received_on, presence: true
  validates :reference, length: { maximum: 200 }, allow_blank: true
  validate :currency_matches_invoice

  scope :completed, -> { where(status: "completed") }
  scope :refunded, -> { where(status: "refunded") }
  scope :recent_first, -> { order(received_on: :desc, id: :desc) }
  STATUSES.each { |value| define_method(:"#{value}?") { status == value } }

  private

  def generate_public_id = self.public_id ||= "PMT-#{SecureRandom.alphanumeric(10).upcase}"

  def currency_matches_invoice
    return if finance_invoice.nil? || currency == finance_invoice.currency

    errors.add(:currency, :invalid)
  end
end
