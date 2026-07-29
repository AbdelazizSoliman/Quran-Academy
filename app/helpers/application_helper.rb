module ApplicationHelper
  include Pagy::Method

  BUTTON_VARIANTS = {
    primary: "bg-app-primary text-white shadow-sm hover:bg-app-primary-hover",
    secondary: "border border-app-border bg-app-surface text-app-text shadow-sm hover:bg-app-muted",
    outline: "border border-app-primary text-app-primary hover:bg-app-primary-soft",
    ghost: "text-app-secondary hover:bg-app-muted hover:text-app-text",
    danger: "bg-app-danger text-white shadow-sm hover:bg-red-800"
  }.freeze

  BUTTON_SIZES = {
    small: "min-h-9 px-3 py-1.5 text-xs",
    medium: "min-h-11 px-4 py-2.5 text-sm",
    large: "min-h-12 px-5 py-3 text-base"
  }.freeze

  BADGE_VARIANTS = {
    default: "bg-app-primary-soft text-app-primary",
    success: "bg-emerald-50 text-emerald-700 ring-emerald-600/15",
    warning: "bg-amber-50 text-amber-700 ring-amber-600/15",
    danger: "bg-red-50 text-red-700 ring-red-600/15",
    information: "bg-blue-50 text-blue-700 ring-blue-600/15",
    neutral: "bg-slate-100 text-slate-700 ring-slate-500/15"
  }.freeze

  ALERT_VARIANTS = {
    success: { classes: "border-emerald-200 bg-emerald-50 text-emerald-900", icon: :check_circle, role: "status" },
    warning: { classes: "border-amber-200 bg-amber-50 text-amber-900", icon: :warning, role: "status" },
    error: { classes: "border-red-200 bg-red-50 text-red-900", icon: :x_circle, role: "alert" },
    information: { classes: "border-blue-200 bg-blue-50 text-blue-900", icon: :information, role: "status" }
  }.freeze

  ICON_SIZES = {
    4 => "size-4",
    5 => "size-5",
    6 => "size-6"
  }.freeze

  # SVG path data is kept inline so icons stay local and require no runtime dependency.
  # rubocop:disable Layout/LineLength
  ICON_PATHS = {
    arrow: '<path stroke-linecap="round" stroke-linejoin="round" d="m9 18 6-6-6-6"/>',
    bars: '<path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h16"/>',
    bell: '<path stroke-linecap="round" stroke-linejoin="round" d="M14.9 18a3 3 0 0 1-5.8 0M18 8a6 6 0 1 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9"/>',
    calendar: '<path stroke-linecap="round" stroke-linejoin="round" d="M7 3v3m10-3v3M4 9h16M5 5h14a1 1 0 0 1 1 1v14H4V6a1 1 0 0 1 1-1Z"/>',
    check: '<path stroke-linecap="round" stroke-linejoin="round" d="m5 12 4 4L19 6"/>',
    check_circle: '<path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>',
    chevron_down: '<path stroke-linecap="round" stroke-linejoin="round" d="m6 9 6 6 6-6"/>',
    close: '<path stroke-linecap="round" stroke-linejoin="round" d="M6 6l12 12M18 6 6 18"/>',
    dots: '<path stroke-linecap="round" stroke-linejoin="round" d="M5 12h.01M12 12h.01M19 12h.01"/>',
    empty: '<path stroke-linecap="round" stroke-linejoin="round" d="M4 7h16v13H4V7Zm3-3h10M8 11h8M8 15h5"/>',
    home: '<path stroke-linecap="round" stroke-linejoin="round" d="m3 11 9-8 9 8v10h-6v-6H9v6H3V11Z"/>',
    information: '<path stroke-linecap="round" stroke-linejoin="round" d="M12 16v-4m0-4h.01m9 4a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>',
    message: '<path stroke-linecap="round" stroke-linejoin="round" d="M4 5h16v12H8l-4 4V5Zm4 5h8m-8 3h5"/>',
    plus: '<path stroke-linecap="round" stroke-linejoin="round" d="M12 5v14M5 12h14"/>',
    reports: '<path stroke-linecap="round" stroke-linejoin="round" d="M5 20V10h4v10H5Zm6 0V4h4v16h-4Zm6 0v-7h4v7h-4Z"/>',
    search: '<path stroke-linecap="round" stroke-linejoin="round" d="m21 21-4.3-4.3m2.3-5.2a7.5 7.5 0 1 1-15 0 7.5 7.5 0 0 1 15 0Z"/>',
    settings: '<path stroke-linecap="round" stroke-linejoin="round" d="M12 15.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7Zm7-3.5 2-1-2-3-2 .5-1.5-1L15 5h-6l-.5 2.5-1.5 1L5 8l-2 3 2 1v2l-2 1 2 3 2-.5 1.5 1L9 21h6l.5-2.5 1.5-1 2 .5 2-3-2-1v-2Z"/>',
    spinner: '<path stroke-linecap="round" d="M12 3a9 9 0 1 0 9 9"/>',
    users: '<path stroke-linecap="round" stroke-linejoin="round" d="M16 20v-1.5A3.5 3.5 0 0 0 12.5 15h-5A3.5 3.5 0 0 0 4 18.5V20m6-9a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7Zm7-1a3 3 0 0 1 0 5.8M18 15a3.5 3.5 0 0 1 3 3.5V20"/>',
    wallet: '<path stroke-linecap="round" stroke-linejoin="round" d="M4 6h15a2 2 0 0 1 2 2v11H4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h13v2m0 6h4m-4 0h.01"/>',
    warning: '<path stroke-linecap="round" stroke-linejoin="round" d="M12 4 3 20h18L12 4Zm0 6v4m0 3h.01"/>',
    x_circle: '<path stroke-linecap="round" stroke-linejoin="round" d="m9 9 6 6m0-6-6 6m12-3a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>'
  }.freeze
  # rubocop:enable Layout/LineLength

  def button_classes(variant: :primary, size: :medium, icon_only: false)
    base = "inline-flex items-center justify-center gap-2 rounded-xl font-semibold transition " \
           "focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 " \
           "focus-visible:outline-app-primary " \
           "disabled:cursor-not-allowed disabled:opacity-55"
    dimensions = if icon_only
                   { small: "size-9", medium: "size-11", large: "size-12" }.fetch(size.to_sym)
                 else
                   BUTTON_SIZES.fetch(size.to_sym)
                 end
    "#{base} #{BUTTON_VARIANTS.fetch(variant.to_sym)} #{dimensions}"
  end

  def badge_classes(variant = :default)
    "inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-semibold ring-1 ring-inset " \
      "#{BADGE_VARIANTS.fetch(variant.to_sym)}"
  end

  def alert_config(variant)
    ALERT_VARIANTS.fetch(variant.to_sym)
  end

  def icon(name, size: 5, decorative: true, label: nil, classes: nil)
    attributes = {
      class: [ICON_SIZES.fetch(size), "shrink-0", classes].compact.join(" "),
      viewBox: "0 0 24 24",
      fill: "none",
      stroke: "currentColor",
      "stroke-width": 1.8
    }
    attributes["aria-hidden"] = "true" if decorative
    attributes["aria-label"] = label unless decorative

    tag.svg(**attributes) { ICON_PATHS.fetch(name.to_sym).html_safe } # rubocop:disable Rails/OutputSafety
  end

  def nav_item_classes(active: false)
    base = "group flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition " \
           "focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 " \
           "focus-visible:outline-app-primary"

    return "#{base} bg-app-primary-soft text-app-primary" if active

    "#{base} text-app-secondary hover:bg-app-muted hover:text-app-text"
  end
end
