class AcademyCron
  LOCK_ID = 1_732_026_081_6
  RECURRING_GENERATION_HOUR_UTC = 0
  RECURRING_GENERATION_MINUTE_UTC = 10
  RECURRING_TASK_NAME = "recurring_lesson_generation".freeze
  INVOICE_GENERATION_HOUR_UTC = 0
  INVOICE_GENERATION_MINUTE_UTC = 20
  INVOICE_TASK_NAME = "recurring_invoice_generation".freeze
  INVOICE_REMINDER_HOUR_UTC = 0
  INVOICE_REMINDER_MINUTE_UTC = 30
  INVOICE_REMINDER_TASK_NAME = "invoice_overdue_reminders".freeze

  def initialize(now: Time.current, connection: ActiveRecord::Base.connection)
    @now = now
    @connection = connection
  end

  def call
    return false unless acquire_lock

    run_reminder_sweeps
    run_recurring_generation_if_due
    run_invoice_generation_if_due
    run_invoice_reminders_if_due
    true
  ensure
    release_lock if @lock_acquired
  end

  private

  def acquire_lock
    value = @connection.select_value("SELECT pg_try_advisory_lock(#{LOCK_ID})")
    @lock_acquired = ActiveModel::Type::Boolean.new.cast(value)
  end

  def release_lock
    @connection.select_value("SELECT pg_advisory_unlock(#{LOCK_ID})")
  rescue StandardError => e
    Rails.logger.error("Academy cron advisory unlock failed exception=#{e.class}")
  end

  def run_reminder_sweeps
    actor = User.find(ENV.fetch("NOTIFICATION_ACTOR_ID"))
    Notifications::LessonReminderScheduler.new(actor:, now: @now).call
    Notifications::LateAttendanceReminderScheduler.new(actor:, now: @now).call
  rescue StandardError => e
    Rails.logger.error("Academy cron reminder sweep failed exception=#{e.class}")
  end

  def run_recurring_generation_if_due
    return unless recurring_generation_due?

    run = CronRun.create!(task_name: RECURRING_TASK_NAME, run_on: utc_date, started_at: Time.current)
    actor = User.find(ENV.fetch("SCHEDULING_ACTOR_ID"))
    EnrollmentLessonSchedules::GenerationSweep.new(actor:).call
    run.update!(completed_at: Time.current)
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    nil
  rescue StandardError => e
    run&.destroy!
    Rails.logger.error("Academy cron recurring generation failed exception=#{e.class}")
  end

  def recurring_generation_due?
    utc_minutes = (@now.utc.hour * 60) + @now.utc.min
    due_minutes = (RECURRING_GENERATION_HOUR_UTC * 60) + RECURRING_GENERATION_MINUTE_UTC
    utc_minutes >= due_minutes && !CronRun.exists?(task_name: RECURRING_TASK_NAME, run_on: utc_date)
  end

  def run_invoice_generation_if_due
    return unless invoice_generation_due?

    run = CronRun.create!(task_name: INVOICE_TASK_NAME, run_on: utc_date, started_at: Time.current)
    actor = User.find(ENV.fetch("FINANCE_ACTOR_ID"))
    Finance::RecurringInvoiceGeneration.new(actor:, today: utc_date).call
    run.update!(completed_at: Time.current)
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    nil
  rescue StandardError => e
    run&.destroy!
    Rails.logger.error("Academy cron invoice generation failed exception=#{e.class}")
  end

  def invoice_generation_due?
    utc_minutes = (@now.utc.hour * 60) + @now.utc.min
    due_minutes = (INVOICE_GENERATION_HOUR_UTC * 60) + INVOICE_GENERATION_MINUTE_UTC
    utc_minutes >= due_minutes && !CronRun.exists?(task_name: INVOICE_TASK_NAME, run_on: utc_date)
  end

  def run_invoice_reminders_if_due
    return unless invoice_reminders_due?

    run = CronRun.create!(task_name: INVOICE_REMINDER_TASK_NAME, run_on: utc_date, started_at: Time.current)
    actor = User.find(ENV.fetch("FINANCE_ACTOR_ID"))
    Notifications::InvoiceOverdueReminderScheduler.new(actor:, today: utc_date).call
    run.update!(completed_at: Time.current)
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    nil
  rescue StandardError => e
    run&.destroy!
    Rails.logger.error("Academy cron invoice reminders failed exception=#{e.class}")
  end

  def invoice_reminders_due?
    utc_minutes = (@now.utc.hour * 60) + @now.utc.min
    due_minutes = (INVOICE_REMINDER_HOUR_UTC * 60) + INVOICE_REMINDER_MINUTE_UTC
    utc_minutes >= due_minutes && !CronRun.exists?(task_name: INVOICE_REMINDER_TASK_NAME, run_on: utc_date)
  end

  def utc_date = @now.utc.to_date
end
