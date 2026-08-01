module Admin
  module LessonReports
    class Transition
      RULES = {
        review: { from: %w[submitted], to: "reviewed", event: "reviewed" },
        lock: { from: %w[submitted reviewed], to: "locked", event: "locked" },
        relock: { from: %w[reopened], to: "locked", event: "relocked" }
      }.freeze

      def initialize(actor:, report:, action:)
        @actor = actor
        @report = report
        @action = action.to_sym
      end

      def call
        rule = RULES.fetch(@action)
        return invalid(validation_error(rule)) if validation_error(rule)
        return @report if @report.status == rule[:to]

        LessonReport.transaction { transition!(rule) }
        @report
      rescue ActiveRecord::RecordInvalid, ActiveRecord::StaleObjectError
        invalid(:stale_record)
      end

      private

      def validation_error(rule)
        return :forbidden unless @actor.active? && @actor.admin?
        return :invalid_transition unless @report.status.in?(rule[:from]) || @report.status == rule[:to]

        :unresolved_entries if locking? && @report.unresolved_entries?
      end

      def transition!(rule)
        previous = @report.status
        now = Time.current
        attributes = { status: rule[:to], updated_by: @actor }
        attributes.merge!(reviewed_at: now, reviewed_by: @actor) if @action == :review
        attributes.merge!(locked_at: now, locked_by: @actor) if locking?
        @report.update!(attributes)
        LessonReportEvent.create!(lesson_report: @report, actor: @actor, event_type: rule[:event],
                                  before_data: { "status" => previous }, after_data: { "status" => rule[:to] })
      end

      def locking? = @action.in?(%i[lock relock])

      def invalid(error)
        @report.errors.add(:base, error)
        @report
      end
    end
  end
end
