class CronRun < ApplicationRecord
  validates :task_name, :run_on, presence: true
  validates :task_name, uniqueness: { scope: :run_on }
end
