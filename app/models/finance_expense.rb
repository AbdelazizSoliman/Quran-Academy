class FinanceExpense < ApplicationRecord
  STATUSES = %w[draft approved paid cancelled].freeze
  CATEGORIES = %w[technology marketing rent utilities supplies administration other].freeze

  belongs_to :created_by, class_name: "User"
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :paid_by, class_name: "User", optional: true
  belongs_to :cancelled_by, class_name: "User", optional: true
  has_many :ledger_entries, as: :source, class_name: "FinanceLedgerEntry", dependent: :restrict_with_exception

  attr_readonly :public_id, :amount, :currency, :incurred_on, :created_by_id
  before_validation :generate_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\AEXP-[A-Z0-9]{10}\z/ }
  validates :status, inclusion: { in: STATUSES }
  validates :category, inclusion: { in: CATEGORIES }
  validates :currency, inclusion: { in: StudentProfile::CURRENCIES }
  validates :amount, numericality: { greater_than: 0 }
  validates :incurred_on, :description, presence: true
  validates :description, length: { maximum: 2_000 }
  validates :vendor, :reference, length: { maximum: 200 }, allow_blank: true
  validates :payment_method, inclusion: { in: FinancePayment::METHODS }

  scope :recent_first, -> { order(incurred_on: :desc, id: :desc) }

  private

  def generate_public_id = self.public_id ||= "EXP-#{SecureRandom.alphanumeric(10).upcase}"
end
