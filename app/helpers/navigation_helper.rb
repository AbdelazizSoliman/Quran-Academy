module NavigationHelper
  ADMIN_VISIBLE_NAVIGATION = %i[
    dashboard students teachers schedule profits_analytics finance fee_plans financial_reports
  ].freeze

  NAVIGATION_ITEMS = {
    dashboard: { icon: :home, roles: %i[admin staff teacher student guardian] },
    users: { icon: :users, roles: %i[admin], path: :admin_users_path },
    invitations: { icon: :users, roles: %i[admin], path: :admin_account_invitations_path },
    students: { icon: :users, roles: %i[admin], path: :admin_students_path },
    guardians: { icon: :users, roles: %i[admin], path: :admin_guardians_path },
    teachers: { icon: :users, roles: %i[admin], path: :admin_teachers_path },
    teacher_profile: { icon: :users, roles: %i[teacher], path: :teacher_profile_path },
    student_profile: { icon: :users, roles: %i[student], path: :student_profile_path },
    guardian_children: { icon: :users, roles: %i[guardian], path: :guardian_students_path },
    guardian_schedule: { icon: :calendar, roles: %i[guardian], path: :guardian_schedule_index_path },
    guardian_attendance: { icon: :check_circle, roles: %i[guardian], path: :guardian_attendances_path },
    guardian_reports: { icon: :reports, roles: %i[guardian], path: :guardian_reports_path },
    guardian_notifications: { icon: :message, roles: %i[guardian], path: :guardian_notifications_path },
    guardian_profile: { icon: :users, roles: %i[guardian], path: :guardian_profile_path },
    fee_plans: { icon: :wallet, roles: %i[admin], path: :admin_fee_plans_path },
    programs: { icon: :reports, roles: %i[admin], path: :admin_programs_path },
    course_offerings: { icon: :calendar, roles: %i[admin], path: :admin_course_offerings_path },
    enrollments: { icon: :check_circle, roles: %i[admin], path: :admin_enrollments_path },
    my_enrollments: { icon: :reports, roles: %i[student], path: :student_enrollments_path },
    teacher_availability: { icon: :calendar, roles: %i[admin], path: :admin_teacher_availabilities_path },
    teacher_schedule: { icon: :calendar, roles: %i[teacher], path: :teacher_schedule_index_path },
    teacher_availability_self: { icon: :calendar, roles: %i[teacher], path: :teacher_availabilities_path },
    student_schedule: { icon: :calendar, roles: %i[student], path: :student_schedule_index_path },
    schedule: { icon: :calendar, roles: %i[admin staff], path: :admin_scheduled_lessons_path },
    profits_analytics: { icon: :reports, roles: %i[admin], path: :admin_academic_dashboard_path },
    finance: { icon: :wallet, roles: %i[admin], path: :admin_teacher_payrolls_path },
    financial_reports: { icon: :reports, roles: %i[admin], path: :admin_operational_reports_path },
    attendance: { icon: :check_circle, roles: %i[admin staff teacher student] },
    whatsapp: { icon: :message, roles: %i[admin staff teacher student] },
    payroll: { icon: :wallet, roles: %i[admin teacher], feature: :payroll },
    reports: { icon: :reports, roles: %i[admin staff teacher] },
    assessments: { icon: :reports, roles: %i[admin staff teacher student] },
    exams: { icon: :calendar, roles: %i[admin staff teacher], feature: :exams },
    certificates: { icon: :check_circle, roles: %i[admin staff student], feature: :certificates },
    academic_progress: { icon: :reports, roles: %i[admin staff teacher student] },
    notifications: { icon: :message, roles: %i[admin staff teacher student] },
    settings: { icon: :settings, roles: %i[admin], path: :admin_settings_path }
  }.freeze

  def nav_item_classes(active: false)
    base = "group flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition " \
           "focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 " \
           "focus-visible:outline-white"

    return "#{base} bg-white/15 text-white shadow-sm" if active

    "#{base} text-emerald-50/75 hover:bg-white/10 hover:text-white"
  end

  def navigation_items_for(user)
    role = user&.role&.to_sym
    permitted_items = NAVIGATION_ITEMS.select do |_key, item|
      permitted_role = role.nil? || item[:roles].include?(role)
      enabled_feature = item[:feature].nil? || ReleaseFeatures.enabled?(item[:feature])
      permitted_role && enabled_feature
    end

    return permitted_items unless role == :admin

    ADMIN_VISIBLE_NAVIGATION.to_h { |key| [key, permitted_items.fetch(key)] }
  end

  def navigation_path(key, item)
    return public_send(item[:path]) if item[:path]
    return root_path if key == :dashboard

    role_specific_navigation_path(key)
  end

  def role_specific_navigation_path(key)
    return assessment_navigation_path if key == :assessments
    return exam_navigation_path if key == :exams
    return current_user&.student? ? student_certificates_path : admin_certificates_path if key == :certificates
    return academic_progress_navigation_path if key == :academic_progress
    return attendance_navigation_path if key == :attendance
    return whatsapp_navigation_path if key == :whatsapp
    return notification_navigation_path if key == :notifications
    return current_user&.teacher? ? teacher_payrolls_path : admin_teacher_payrolls_path if key == :payroll
    return current_user&.teacher? ? teacher_reports_path : admin_operational_reports_path if key == :reports

    raise KeyError, "No navigation path configured for #{key.inspect}"
  end

  def attendance_navigation_path
    return student_attendances_path if current_user&.student?
    return teacher_schedule_index_path if current_user&.teacher?

    admin_lesson_attendances_path
  end

  def whatsapp_navigation_path
    return student_notifications_path if current_user&.student?
    return teacher_notifications_path if current_user&.teacher?

    admin_notifications_path
  end

  def assessment_navigation_path
    return teacher_assessments_path if current_user&.teacher?
    return student_assessments_path if current_user&.student?

    admin_student_assessments_path
  end

  def exam_navigation_path
    current_user&.teacher? ? teacher_exams_path : admin_exam_sessions_path
  end

  def academic_progress_navigation_path
    return teacher_academic_dashboard_path if current_user&.teacher?
    return student_progress_path if current_user&.student?

    admin_academic_dashboard_path
  end

  def notification_navigation_path
    return teacher_notifications_path if current_user&.teacher?
    return student_notifications_path if current_user&.student?

    admin_notifications_path
  end
end
