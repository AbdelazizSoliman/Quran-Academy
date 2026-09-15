# rubocop:disable Metrics/BlockLength
namespace :diagnostics do
  desc "Read-only diagnostics for WhatsApp lesson reminders (lessons 1 and 10)"
  task lesson_reminders: :environment do
    puts "=== Lesson Reminder Diagnostic ==="

    mask_number = lambda do |value|
      digits = value.to_s.gsub(/\D/, "")
      if digits.length >= 4
        "****#{digits.last(4)}"
      elsif value.present?
        "masked"
      else
        "blank"
      end
    end

    lesson_ids = [1, 10]
    lessons = ScheduledLesson.where(id: lesson_ids).includes(
      { teacher_profile: :user },
      scheduled_lesson_enrollments: { student_profile: :user }
    ).index_by(&:id)

    lesson_ids.each do |lesson_id|
      lesson = lessons[lesson_id]
      unless lesson
        puts "LESSON #{lesson_id}: NOT_FOUND"
        next
      end

      puts "LESSON #{lesson.id}"
      puts "  status=#{lesson.status}"
      puts "  delivery_mode=#{lesson.delivery_mode}"
      puts "  online_meeting_url_present=#{lesson.online_meeting_url.present?}"
      puts "  safe_online_meeting_join_url_present=#{lesson.safe_online_meeting_join_url.present?}"

      recipients = [["teacher", lesson.teacher_profile&.user]]
      lesson.scheduled_lesson_enrollments.select(&:expected?).each do |participation|
        recipients << ["student", participation.student_profile&.user]
      end
      recipients = recipients.compact.uniq { |(_, user)| user.id }

      recipients.each do |role, user|
        profile = user.teacher_profile || user.student_profile
        raw_number = profile&.whatsapp_number.presence || profile&.phone_number
        normalized = Notifications::E164Normalizer.call(raw_number)
        # Avoid the resolver's AcademySetting.current fallback when malformed legacy data has
        # no preferred locale; the diagnostic must never create a singleton setting row.
        resolved = if user.preferred_locale.present?
                     Notifications::RecipientResolver.new(user:, channel: "whatsapp").call
                   else
                     Notifications::Recipient.new(false, user, nil, nil, nil, "unavailable", "unavailable",
                                                  :missing_preferred_locale)
                   end
        join_suffix_present = false

        if lesson.safe_online_meeting_join_url.present?
          join_url = Notifications::LessonJoinUrlBuilder.call(lesson:, recipient: user)
          join_suffix_present = Notifications::LessonJoinUrlSuffix.call(join_url:).present?
        end

        puts "  #{role}"
        puts "    user_id=#{user.id}"
        puts "    whatsapp_selected=#{Notifications::LessonReminderRecipient.whatsapp_selected?(user)}"
        puts "    number_present=#{raw_number.present?}"
        puts "    masked_number=#{mask_number.call(raw_number)}"
        puts "    e164_valid=#{normalized.valid?}"
        puts "    resolver_valid=#{resolved.valid?}"
        puts "    resolver_error=#{resolved.error.inspect}" if resolved.error
        puts "    join_suffix_present=#{join_suffix_present}"

        Notification.where(source_type: "ScheduledLesson", source_id: lesson.id,
                           notification_type: %w[lesson_pre_reminder lesson_late_reminder],
                           recipient_user_id: user.id).order(:id).each do |notification|
          puts "    notification id=#{notification.id} type=#{notification.notification_type} " \
               "recipient_user_id=#{notification.recipient_user_id} status=#{notification.status} " \
               "failure_code=#{notification.failure_code.inspect} " \
               "http_status=#{notification.http_status.inspect} " \
               "provider_status=#{notification.provider_status.inspect} " \
               "idempotency_key=#{notification.idempotency_key.inspect}"

          notification.attempts.order(:attempt_number).each do |attempt|
            puts "      attempt status=#{attempt.status} " \
                 "http_status=#{attempt.http_status.inspect} " \
                 "provider_status=#{attempt.provider_status.inspect} " \
                 "error_code=#{attempt.error_code.inspect}"
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
