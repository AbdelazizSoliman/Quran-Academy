class FinanceLedgerEntry < ApplicationRecord
  ENTRY_TYPES = %w[invoice_issued invoice_cancelled payment_received payment_refunded expense_paid payroll_paid].freeze
  ACCOUNTS = %w[accounts_receivable revenue cash expense payroll_expense payroll_payable].freeze
  DIRECTIONS = %w[debit credit].freeze

  belongs_to :source, polymorphic: true
  belongs_to :actor, class_name: "User"

  attr_readonly :public_id, :entry_type, :account, :direction, :amount, :currency, :occurred_on,
                :source_type, :source_id, :actor_id, :description
  before_validation :generate_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\ALED-[A-Z0-9]{10}\z/ }
  validates :entry_type, inclusion: { in: ENTRY_TYPES }
  validates :account, inclusion: { in: ACCOUNTS }
  validates :direction, inclusion: { in: DIRECTIONS }
  validates :currency, inclusion: { in: StudentProfile::CURRENCIES }
  validates :amount, numericality: { greater_than: 0 }
  validates :occurred_on, presence: true

  scope :recent_first, -> { order(occurred_on: :desc, id: :desc) }

  def readonly? = persisted?

  private

  def generate_public_id = self.public_id ||= "LED-#{SecureRandom.alphanumeric(10).upcase}"
end
