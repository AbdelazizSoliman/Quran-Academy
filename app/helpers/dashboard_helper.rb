module DashboardHelper
  def dashboard_schedule_path
    return teacher_schedule_index_path if current_user&.teacher?
    return student_schedule_index_path if current_user&.student?

    admin_scheduled_lessons_path
  end

  def dashboard_attendance_path
    attendance_navigation_path
  end

  def dashboard_reports_path
    return teacher_reports_path if current_user&.teacher?
    return student_reports_path if current_user&.student?

    admin_operational_reports_path
  end

  def dashboard_lesson_title(lesson)
    I18n.locale == :ar ? lesson.title_ar : lesson.title_en
  end

  def dashboard_lesson_location(lesson)
    lesson.location_name.presence || t("scheduling.catalogs.delivery_modes.#{lesson.delivery_mode}")
  end
end
