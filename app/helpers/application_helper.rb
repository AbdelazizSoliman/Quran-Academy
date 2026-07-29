module ApplicationHelper
  include Pagy::Method

  def nav_item_classes(active: false)
    base = "group flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium " \
           "transition focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 " \
           "focus-visible:outline-emerald-500"

    active ? "#{base} bg-emerald-50 text-emerald-800" : "#{base} text-slate-600 hover:bg-slate-50 hover:text-slate-900"
  end
end
