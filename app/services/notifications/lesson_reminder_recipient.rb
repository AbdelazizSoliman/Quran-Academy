module Notifications
  class LessonReminderRecipient
    def self.whatsapp_selected?(user)
      profile = user.teacher_profile || user.student_profile
      case profile
      when TeacherProfile then profile.notification_method.in?(%w[whatsapp both])
      when StudentProfile then profile.preferred_contact_method == "whatsapp"
      else false
      end
    end
  end
end
