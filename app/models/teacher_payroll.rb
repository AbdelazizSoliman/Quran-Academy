class TeacherPayroll < ApplicationRecord
  STATUSES = %w[draft prepared approved paid cancelled].freeze
  STRATEGIES = %w[per_lesson hourly monthly_fixed manual_amount].freeze

  belongs_to :teacher_profile
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"
  belongs_to :prepared_by, class_name: "User", optional: true
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :paid_by, class_name: "User", optional: true
  belongs_to :cancelled_by, class_name: "User", optional: true
  has_many :items, class_name: "TeacherPayrollItem", dependent: :restrict_with_exception
  has_many :events, class_name: "TeacherPayrollEvent", dependent: :restrict_with_exception

  attr_readonly :public_id, :teacher_profile_id, :period_starts_on, :period_ends_on, :calculation_strategy, :currency
  before_validation :generate_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\APAY-[A-Z0-9]{10}\z/ }
  validates :status, inclusion: { in: STATUSES }
  validates :calculation_strategy, inclusion: { in: STRATEGIES }
  validates :currency, format: { with: AcademySetting::CURRENCY_PATTERN }
  validates :teacher_profile_id, uniqueness: { scope: %i[period_starts_on period_ends_on] }
  validates :period_starts_on, :period_ends_on, presence: true
  validates :rate, :base_amount, :bonus_amount, :deduction_amount,
            numericality: { greater_than_or_equal_to: 0 }
  validates :manual_adjustment_amount, :net_amount, numericality: true
  validates :notes, :adjustment_reason, :cancellation_reason, length: { maximum: 2_000 }, allow_blank: true
  validate :period_order

  scope :recent_first, -> { order(period_starts_on: :desc, id: :desc) }
  STATUSES.each { |value| define_method(:"#{value}?") { status == value } }

  def recalculate_net
    self.net_amount = base_amount + bonus_amount - deduction_amount + manual_adjustment_amount
  end

  private

  def generate_public_id = self.public_id ||= "PAY-#{SecureRandom.alphanumeric(10).upcase}"

  def period_order
    return unless period_ends_on && period_starts_on && period_ends_on < period_starts_on

    errors.add(:period_ends_on,
               :before_start)
  end
end
