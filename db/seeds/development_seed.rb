# Declarative scenario builders are intentionally kept together so relationships stay visible.
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/ModuleLength
# rubocop:disable Metrics/PerceivedComplexity
module DevelopmentSeed
  extend FactoryBot::Syntax::Methods

  MARKER_EMAIL = "admin@demo.quran-academy.test".freeze
  PASSWORD = "DemoPass123!".freeze

  module_function

  def call
    return print_existing if User.exists?(email: MARKER_EMAIL)

    FactoryBot.find_definitions unless FactoryBot.factories.registered?(:user)
    previous_delivery = ActionMailer::Base.perform_deliveries
    ActionMailer::Base.perform_deliveries = false
    ActiveRecord::Base.transaction { build_dataset }
    print_summary
  ensure
    ActionMailer::Base.perform_deliveries = previous_delivery unless previous_delivery.nil?
  end

  def build_dataset
    @admin = demo_user(:admin, "admin", "Academy", "Administrator", locale: "en")
    @staff = demo_user(:staff, "staff", "Mariam", "Coordinator", locale: "ar")
    create(:staff_profile, user: @staff, created_by: @admin, updated_by: @admin,
                           phone_number: "+201110000001", whatsapp_number: "+201110000001")
    @teachers = create_teachers
    @students = create_students
    create_guardian_links
    @programs = create_programs
    @offerings = create_offerings
    @enrollments = create_enrollments
    @lessons = create_lessons
    create_attendance_and_reports
    create_academic_progress
    create_payrolls
    create_invitation_history
    create_notification_history
  end

  def demo_user(role, slug, first_name, last_name, locale:)
    create(:user, role, :active, email: "#{slug}@demo.quran-academy.test", first_name:, last_name:,
                                 preferred_locale: locale, password: PASSWORD, password_confirmation: PASSWORD)
  end

  def create_teachers
    names = [%w[Ahmad Hassan], %w[Fatimah Ali], %w[Yusuf Ibrahim]]
    names.each_with_index.map do |(first_name, last_name), index|
      user = demo_user(:teacher, "teacher#{index + 1}", first_name, last_name, locale: index.zero? ? "en" : "ar")
      profile = create(:teacher_profile, :active, :verified, user:, created_by: @admin, updated_by: @admin,
                                                             display_name: "#{first_name} #{last_name}",
                                                             phone_number: "+20112000000#{index + 1}",
                                                             whatsapp_number: "+20112000000#{index + 1}")
      create(:teacher_availability, teacher_profile: profile, created_by: @admin, updated_by: @admin,
                                    weekday: %w[sunday monday tuesday][index], starts_at_local: "09:00",
                                    ends_at_local: "17:00")
      profile
    end
  end

  def create_students
    10.times.map do |index|
      user = demo_user(:student, "student#{index + 1}", "Student", format("%02d", index + 1), locale: "en")
      create(:student_profile, user:, created_by: @admin, updated_by: @admin,
                               display_name: user.full_name, student_type: index < 2 ? "minor" : "adult",
                               date_of_birth: (index < 2 ? 10 : 24).years.ago.to_date,
                               phone_number: "+2011300000#{format('%02d', index + 1)}",
                               whatsapp_number: "+2011300000#{format('%02d', index + 1)}",
                               preferred_contact_method: index < 2 ? "guardian" : "whatsapp")
    end
  end

  def create_guardian_links
    @students.first(2).each_with_index do |student, index|
      guardian = create(:guardian, full_name: "Guardian #{index + 1}",
                                   email: "guardian#{index + 1}@demo.quran-academy.test",
                                   phone_number: "+20114000000#{index + 1}",
                                   whatsapp_number: "+20114000000#{index + 1}", created_by: @admin, updated_by: @admin)
      create(:student_guardianship, student_profile: student, guardian:, created_by: @admin, updated_by: @admin,
                                    primary_contact: true, emergency_contact: true,
                                    can_make_academic_decisions: true)
    end
  end

  def create_programs
    [
      ["DEMO_READING", "برنامج القراءة", "Quran Reading", "quran_reading"],
      ["DEMO_HIFZ", "برنامج الحفظ", "Quran Memorization", "quran_memorization"]
    ].map do |code, name_ar, name_en, category|
      create(:program, :active, code:, name_ar:, name_en:, category:, created_by: @admin, updated_by: @admin)
    end
  end

  def create_offerings
    @programs.each_with_index.flat_map do |program, program_index|
      2.times.map do |index|
        create(:course_offering, :open, program:, code: "DEMO_OFR_#{program_index + 1}_#{index + 1}",
                                        title_en: "#{program.name_en} Group #{index + 1}",
                                        title_ar: "#{program.name_ar} - المجموعة #{index + 1}",
                                        created_by: @admin, updated_by: @admin)
      end
    end
  end

  def create_enrollments
    @students.each_with_index.map do |student, index|
      create(:enrollment, index < 8 ? :active : :approved, student_profile: student,
                                                           course_offering: @offerings[index % @offerings.length],
                                                           created_by: @admin, updated_by: @admin)
    end
  end

  def create_lessons
    statuses = %w[scheduled in_progress completed cancelled]
    statuses.each_with_index.map do |status, index|
      starts_at = status.in?(%w[completed cancelled]) ? (index + 2).days.ago : (index + 1).days.from_now
      attributes = { course_offering: @offerings[index], teacher_profile: @teachers[index % @teachers.length],
                     created_by: @admin, updated_by: @admin, status:, starts_at: starts_at.change(hour: 10),
                     ends_at: starts_at.change(hour: 11), title_en: "Demo #{status.humanize} Lesson",
                     title_ar: "حلقة تجريبية - #{status}", online_meeting_url: "https://example.test/demo-lesson-#{index}" }
      if status == "in_progress"
        attributes.merge!(started_at: starts_at.change(hour: 10), attendance_status: "open",
                          attendance_opened_at: starts_at.change(hour: 10))
      end
      if status == "completed"
        attributes.merge!(started_at: starts_at.change(hour: 10), ended_at: starts_at.change(hour: 11),
                          attendance_status: "locked", attendance_opened_at: starts_at.change(hour: 10),
                          attendance_locked_at: starts_at.change(hour: 11), attendance_locked_by: @admin)
      end
      if status == "cancelled"
        attributes.merge!(cancellation_reason: "Demo cancellation", cancelled_by: @admin,
                          cancelled_at: starts_at.change(hour: 9))
      end
      create(:scheduled_lesson, **attributes)
    end
  end

  def participants_for(lesson)
    matching = @enrollments.select { |enrollment| enrollment.course_offering_id == lesson.course_offering_id }
    matching.first(4).map do |enrollment|
      create(:scheduled_lesson_enrollment, scheduled_lesson: lesson, enrollment:, added_by: @admin)
    end
  end

  def create_attendance_and_reports
    @lessons.each do |lesson|
      participants = participants_for(lesson)
      next unless lesson.status.in?(%w[in_progress completed])

      statuses = lesson.completed? ? %w[present late absent excused_absence] : %w[present late pending pending]
      participants.each_with_index do |participant, index|
        status = statuses[index % statuses.length]
        arrival = lesson.starts_at + (index * 7).minutes if status.in?(%w[present late])
        create(:lesson_attendance, scheduled_lesson_enrollment: participant, scheduled_lesson: lesson,
                                   status:, arrival_at: arrival, minutes_late: arrival ? [index * 7, 0].max : 0,
                                   excuse_reason: status == "excused_absence" ? "Family reason" : nil,
                                   recorded_by: @teachers.first.user, recorded_at: Time.current)
      end
      create_completed_report(lesson, participants) if lesson.completed?
    end
  end

  def create_completed_report(lesson, participants)
    report = create(:lesson_report, scheduled_lesson: lesson, teacher_profile: lesson.teacher_profile,
                                    created_by: lesson.teacher_profile.user, updated_by: lesson.teacher_profile.user,
                                    status: "locked", lesson_summary: "Completed Quran reading and Tajweed practice.",
                                    topics_covered: "Makharij and fluency", general_homework: "Revise today's passage.",
                                    locked_at: lesson.ended_at, locked_by: @admin)
    participants.each do |participant|
      create(:lesson_student_report, lesson_report: report, scheduled_lesson_enrollment: participant,
                                     created_by: lesson.teacher_profile.user, updated_by: lesson.teacher_profile.user,
                                     status: "completed", reading_material: "Surah Al-Baqarah",
                                     reading_quality: "good", memorization_result: "needs_revision",
                                     revision_result: "good", engagement_level: "engaged",
                                     performance_level: "meeting_expectations", homework: "Repeat verses five times.")
    end
  end

  def create_academic_progress
    category = create(:assessment_category, code: "tajweed", name_en: "Tajweed", name_ar: "التجويد",
                                            created_by: @admin, updated_by: @admin)
    template = create(:assessment_template, name_en: "Monthly Evaluation", name_ar: "التقييم الشهري",
                                            status: "active", created_by: @admin, updated_by: @admin)
    rubric = create(:assessment_rubric_item, assessment_template: template, assessment_category: category,
                                             name_en: "Recitation accuracy", name_ar: "دقة التلاوة")
    @enrollments.first(5).each_with_index do |enrollment, index|
      assessment = create(:student_assessment, enrollment:, student_profile: enrollment.student_profile,
                                               teacher_profile: @teachers[index % @teachers.length],
                                               assessment_template: template, created_by: @admin, updated_by: @admin,
                                               status: "published", overall_score: 72 + (index * 5),
                                               letter_grade: %w[C B B+ A A+][index])
      create(:assessment_score, student_assessment: assessment, assessment_rubric_item: rubric,
                                numeric_score: assessment.overall_score)
      create(:student_progress, student_profile: enrollment.student_profile, latest_assessment: assessment,
                                average_score: assessment.overall_score, highest_score: assessment.overall_score,
                                lowest_score: assessment.overall_score, trend: index.even? ? "improving" : "stable")
    end
    exam = create(:exam_session, program: @programs.first, course_offering: @offerings.first,
                                 teacher_profile: @teachers.first, created_by: @admin, updated_by: @admin,
                                 status: "published", starts_at: 1.week.ago)
    create(:certificate, student_profile: @students.first, enrollment: @enrollments.first,
                         exam_session: exam, certificate_type: "exam_completion", issuer: @admin,
                         issued_on: Date.current)
  end

  def create_payrolls
    %w[draft prepared paid].each_with_index do |status, index|
      create(:teacher_payroll, teacher_profile: @teachers[index], created_by: @admin, updated_by: @admin,
                               status:, period_starts_on: (index + 1).months.ago.beginning_of_month.to_date,
                               period_ends_on: (index + 1).months.ago.end_of_month.to_date,
                               prepared_by: status == "draft" ? nil : @admin,
                               prepared_at: status == "draft" ? nil : Time.current,
                               approved_by: status == "paid" ? @admin : nil,
                               approved_at: status == "paid" ? Time.current : nil,
                               paid_by: status == "paid" ? @admin : nil, paid_at: status == "paid" ? Time.current : nil)
    end
  end

  def create_invitation_history
    %w[pending sent accepted expired cancelled].each_with_index do |status, index|
      user = @students[index].user
      create(:account_invitation, user:, created_by: @admin, status:,
                                  expires_at: status == "expired" ? 1.day.ago : 2.days.from_now,
                                  accepted_at: status == "accepted" ? Time.current : nil)
    end
  end

  def create_notification_history
    %w[pending sent failed].each_with_index do |status, index|
      notification = create(:notification, recipient_user: @students[index].user, actor: @admin,
                                           channel: index == 1 ? "whatsapp" : "email",
                                           provider: index == 1 ? "meta_whatsapp" : "resend",
                                           status:, notification_type: "certificate",
                                           sent_at: status == "sent" ? Time.current : nil,
                                           failed_at: status == "failed" ? Time.current : nil,
                                           failure_code: status == "failed" ? "demo_failure" : nil,
                                           failure_reason: status == "failed" ? "Demonstration provider failure" : nil)
      create(:notification_event, notification:, actor: @admin, event_type: status == "pending" ? "created" : status)
      create(:notification_attempt, notification:, actor: @admin, status:) unless status == "pending"
    end
  end

  def print_existing
    Rails.logger.debug { "Demo data already exists (#{MARKER_EMAIL}); nothing changed." }
  end

  def print_summary
    Rails.logger.debug "Demo data created without external email or WhatsApp delivery."
    Rails.logger.debug { "Admin: #{MARKER_EMAIL} / #{PASSWORD}" }
    Rails.logger.debug { "Staff: staff@demo.quran-academy.test / #{PASSWORD}" }
    Rails.logger.debug { "Teachers: teacher1..3@demo.quran-academy.test / #{PASSWORD}" }
    Rails.logger.debug { "Students: student1..10@demo.quran-academy.test / #{PASSWORD}" }
  end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/ModuleLength
# rubocop:enable Metrics/PerceivedComplexity
