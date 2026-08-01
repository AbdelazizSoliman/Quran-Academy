class TeacherPayrollItem < ApplicationRecord
  belongs_to :teacher_payroll, inverse_of: :items
  belongs_to :scheduled_lesson

  validates :scheduled_lesson_id, uniqueness: { scope: :teacher_payroll_id }
  validates :duration_minutes, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :rate, :amount, numericality: { greater_than_or_equal_to: 0 }
end
