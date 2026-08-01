module Admin
  module LessonReports
    class Reopen
      def initialize(actor:, report:, reason:)
        @actor = actor
        @report = report
        @reason = reason
      end

      def call
        return invalid(validation_error) if validation_error

        LessonReport.transaction { reopen! }
        @report
      rescue ActiveRecord::RecordInvalid, ActiveRecord::StaleObjectError
        invalid(:stale_record)
      end

      private

      def validation_error
        return :forbidden unless @actor.active? && @actor.admin?
        return :reopening_reason_required if @reason.blank?

        :invalid_transition unless @report.locked?
      end

      def reopen!
        now = Time.current
        @report.update!(status: "reopened", reopened_at: now, reopened_by: @actor,
                        reopening_reason: @reason, updated_by: @actor)
        LessonReportEvent.create!(lesson_report: @report, actor: @actor, event_type: "reopened",
                                  before_data: { "status" => "locked" }, after_data: { "status" => "reopened" },
                                  metadata: { "reason" => @reason })
      end

      def invalid(error)
        @report.errors.add(:base, error)
        @report
      end
    end
  end
end
