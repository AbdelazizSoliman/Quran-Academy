module NavigationHelper
  NAVIGATION_ITEMS = {
    dashboard: { icon: :home, roles: %i[admin staff teacher student] },
    users: { icon: :users, roles: %i[admin], path: :admin_users_path },
    students: { icon: :users, roles: %i[admin], path: :admin_students_path },
    guardians: { icon: :users, roles: %i[admin], path: :admin_guardians_path },
    teachers: { icon: :users, roles: %i[admin], path: :admin_teachers_path },
    teacher_profile: { icon: :users, roles: %i[teacher], path: :teacher_profile_path },
    student_profile: { icon: :users, roles: %i[student], path: :student_profile_path },
    programs: { icon: :reports, roles: %i[admin], path: :admin_programs_path },
    course_offerings: { icon: :calendar, roles: %i[admin], path: :admin_course_offerings_path },
    enrollments: { icon: :check_circle, roles: %i[admin], path: :admin_enrollments_path },
    my_enrollments: { icon: :reports, roles: %i[student], path: :student_enrollments_path },
    schedule: { icon: :calendar, roles: %i[admin staff teacher student] },
    attendance: { icon: :check_circle, roles: %i[admin staff teacher student] },
    whatsapp: { icon: :message, roles: %i[admin staff] },
    payroll: { icon: :wallet, roles: %i[admin] },
    reports: { icon: :reports, roles: %i[admin staff teacher] },
    settings: { icon: :settings, roles: %i[admin], path: :admin_settings_path }
  }.freeze

  def nav_item_classes(active: false)
    base = "group flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition " \
           "focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 " \
           "focus-visible:outline-app-primary"

    return "#{base} bg-app-primary-soft text-app-primary" if active

    "#{base} text-app-secondary hover:bg-app-muted hover:text-app-text"
  end

  def navigation_items_for(user)
    role = user&.role&.to_sym
    NAVIGATION_ITEMS.select { |_key, item| role.nil? || item[:roles].include?(role) }
  end

  def navigation_path(key, item)
    return public_send(item[:path]) if item[:path]
    return root_path if key == :dashboard

    "#"
  end
end
