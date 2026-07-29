module NavigationHelper
  NAVIGATION_ITEMS = {
    dashboard: { icon: :home, roles: %i[admin staff teacher student] },
    students: { icon: :users, roles: %i[admin staff] },
    teachers: { icon: :users, roles: %i[admin staff] },
    schedule: { icon: :calendar, roles: %i[admin staff teacher student] },
    attendance: { icon: :check_circle, roles: %i[admin staff teacher student] },
    whatsapp: { icon: :message, roles: %i[admin staff] },
    payroll: { icon: :wallet, roles: %i[admin] },
    reports: { icon: :reports, roles: %i[admin staff teacher] },
    settings: { icon: :settings, roles: %i[admin] }
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
end
