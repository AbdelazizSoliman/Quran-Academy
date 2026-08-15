module EnrollmentLessonSchedules
  GenerationResult = Data.define(:generated, :skipped, :issues)

  class GenerateOccurrences
    DEFAULT_HORIZON = 8.weeks

    def initialize(schedule:, actor:, from_date: nil, through_date: nil)
      @schedule = schedule
      @actor = actor
      @zone = ActiveSupport::TimeZone[@schedule.time_zone]
      @from_date = [@schedule.starts_on, from_date || local_today].max
      horizon = through_date || (local_today + DEFAULT_HORIZON)
      @through_date = [horizon, @schedule.ends_on].compact.min
    end

    def call
      return GenerationResult.new([], [], []) unless @schedule.active? && @from_date <= @through_date

      generated = []
      skipped = []
      issues = []
      @schedule.slots.find_each do |slot|
        matching_dates(slot).each do |date|
          result = generate(slot, date)
          { generated: generated, skipped: skipped, issue: issues }.fetch(result.first) << result.last
        end
      end
      GenerationResult.new(generated, skipped, issues)
    end

    private

    def local_today = Time.current.in_time_zone(@zone).to_date

    def matching_dates(slot)
      (@from_date..@through_date).select { |date| date.strftime("%A").downcase == slot.weekday }
    end

    def generate(slot, date)
      existing = slot.scheduled_lessons.find_by(recurrence_date: date)
      if existing
        resolve_issue(slot, date)
        return [:skipped, existing]
      end

      lesson = nil
      success = false
      ScheduledLesson.transaction(requires_new: true) do
        lesson = create_lesson(slot, date)
        participant = add_participant(lesson)
        if lesson.errors.empty? && participant.errors.empty?
          lesson = schedule_lesson(lesson)
          success = lesson.errors.empty?
        else
          merge_participant_errors!(lesson, participant)
        end
        raise ActiveRecord::Rollback unless success
      end
      return generated(slot, date, lesson) if success

      failed(slot, date, lesson)
    rescue ActiveRecord::RecordNotUnique
      [:skipped, slot.scheduled_lessons.find_by(recurrence_date: date)]
    end

    # Always attaches to :base — lesson.errors.add(participant_attribute, ...) would let Rails try
    # to read that attribute off the *lesson* (a different record) while building the message and
    # raise NoMethodError, since e.g. :enrollment/:student_profile aren't lesson attributes. The
    # participant's original attribute is preserved by folding it into the error type instead.
    def merge_participant_errors!(lesson, participant)
      participant.errors.each do |error|
        composed_type = error.attribute == :base ? error.type : :"#{error.attribute}_#{error.type}"
        lesson.errors.add(:base, composed_type)
      end
    end

    def create_lesson(slot, date)
      starts_at = local_start(date, slot.starts_at_local)
      attributes = @schedule.enrollment ? enrollment_lesson_attributes : direct_lesson_attributes
      Admin::ScheduledLessons::Create.new(
        actor: @actor,
        attributes: attributes.merge(
          teacher_profile_id: @schedule.teacher_profile_id, starts_at:,
          ends_at: starts_at + @schedule.lesson_duration_minutes.minutes, academy_time_zone: @schedule.time_zone,
          location_name: nil, online_meeting_url: nil, scheduling_source: "recurring",
          enrollment_lesson_schedule_slot_id: slot.id, recurrence_date: date
        )
      ).call
    end

    def enrollment_lesson_attributes
      offering = @schedule.enrollment.course_offering
      { course_offering_id: offering.id, title_ar: offering.title_ar, title_en: offering.title_en,
        delivery_mode: lesson_delivery_mode(offering.delivery_mode) }
    end

    def direct_lesson_attributes
      student = @schedule.student_profile
      { course_offering_id: nil, title_ar: "درس خاص مع #{student.display_name}",
        title_en: "Private lesson with #{student.display_name}", delivery_mode: "online" }
    end

    def local_start(date, time)
      @zone.local(date.year, date.month, date.day, time.hour, time.min, time.sec)
    end

    def lesson_delivery_mode(mode)
      mode == "in_person" ? "onsite" : mode
    end

    def add_participant(lesson)
      Admin::ScheduledLessons::Participants::Add.new(
        actor: @actor, lesson:, enrollment: @schedule.enrollment,
        student_profile: @schedule.enrollment ? nil : @schedule.student_profile
      ).call
    end

    def schedule_lesson(lesson)
      Admin::ScheduledLessons::Transition.new(actor: @actor, lesson:, action: :schedule).call
    end

    def generated(slot, date, lesson)
      resolve_issue(slot, date)
      @schedule.events.create!(actor: @actor, event_type: "occurrence_generated",
                               metadata: { "scheduled_lesson_id" => lesson.id, "recurrence_date" => date })
      [:generated, lesson]
    end

    # Records which attribute failed and why (e.g. "online_meeting_url" + :required), not just the
    # bare error type — a reason_code of "required" alone can't distinguish a missing teacher
    # meeting URL from a missing course_offering/enrollment/student_profile.
    def failed(slot, date, lesson)
      pairs = error_detail_pairs(lesson)
      issue = EnrollmentLessonGenerationIssue.find_or_initialize_by(
        enrollment_lesson_schedule_slot: slot, recurrence_date: date
      )
      issue.update!(reason_code: reason_code_for(pairs), details: issue_details(pairs, lesson), resolved_at: nil)
      if issue.previous_changes.key?("id") || issue.previous_changes.key?("reason_code")
        @schedule.events.create!(actor: @actor, event_type: "generation_failed",
                                 metadata: { "recurrence_date" => date, "reason_code" => issue.reason_code })
      end
      [:issue, issue]
    end

    def error_detail_pairs(lesson)
      lesson.errors.details.flat_map do |attribute, details|
        details.map { |detail| [attribute, detail[:error]] }
      end.uniq
    end

    def reason_code_for(pairs)
      return "generation_failed" if pairs.empty?

      attribute, error = pairs.first
      attribute == :base ? error.to_s : "#{attribute}_#{error}"
    end

    def issue_details(pairs, lesson)
      { "reason_codes" => pairs.map { |_, error| error.to_s }.uniq,
        "attributes" => pairs.map { |attribute, _| attribute.to_s }.uniq,
        "messages" => lesson.errors.full_messages }
    end

    def resolve_issue(slot, date)
      issue = EnrollmentLessonGenerationIssue.find_by(enrollment_lesson_schedule_slot: slot, recurrence_date: date)
      issue&.update!(resolved_at: Time.current)
    end
  end
end
