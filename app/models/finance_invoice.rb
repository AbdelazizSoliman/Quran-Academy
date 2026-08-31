class FinanceInvoice < ApplicationRecord
  STATUSES = %w[draft issued partially_paid paid overdue cancelled].freeze

  belongs_to :student_profile
  belongs_to :fee_plan, optional: true
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"
  has_many :payments, class_name: "FinancePayment", dependent: :restrict_with_exception
  has_many :ledger_entries, as: :source, class_name: "FinanceLedgerEntry", dependent: :restrict_with_exception

  attr_readonly :public_id, :student_profile_id, :currency
  before_validation :generate_public_id, on: :create
  before_validation :calculate_total

  validates :public_id, presence: true, uniqueness: true, format: { with: /\AINV-[A-Z0-9]{10}\z/ }
  validates :status, inclusion: { in: STATUSES }
  validates :currency, inclusion: { in: StudentProfile::CURRENCIES }
  validates :subtotal, :discount_amount, :tax_amount, :total_amount,
            numericality: { greater_than_or_equal_to: 0 }
  validates :billing_period_starts_on, :billing_period_ends_on, :due_on, presence: true
  validates :notes, length: { maximum: 2_000 }, allow_blank: true
  validate :period_order
  validate :discount_not_greater_than_subtotal

  scope :recent_first, -> { order(due_on: :desc, id: :desc) }
  scope :outstanding, -> { where(status: %w[issued partially_paid overdue]) }
  STATUSES.each { |value| define_method(:"#{value}?") { status == value } }

  def paid_amount
    payments.completed.sum(:amount)
  end

  def balance_due
    [total_amount - paid_amount, 0.to_d].max
  end

  def effective_status
    return "overdue" if status.in?(%w[issued partially_paid]) && due_on < Date.current

    status
  end

  def deliverable? = status.in?(%w[issued partially_paid paid overdue])

  private

  def generate_public_id = self.public_id ||= "INV-#{SecureRandom.alphanumeric(10).upcase}"
  def calculate_total = self.total_amount = subtotal - discount_amount + tax_amount

  def period_order
    return unless billing_period_starts_on && billing_period_ends_on
    return unless billing_period_ends_on < billing_period_starts_on

    errors.add(:billing_period_ends_on, :before_start)
  end

  def discount_not_greater_than_subtotal
    errors.add(:discount_amount, :less_than_or_equal_to, count: subtotal) if discount_amount.to_d > subtotal.to_d
  end
end
