module ReleaseFeatures
  FEATURES = %i[exams certificates payroll].freeze

  module_function

  def enabled?(feature)
    feature = feature.to_sym
    raise ArgumentError, "unknown release feature: #{feature}" unless FEATURES.include?(feature)

    configured = ENV.fetch("FEATURE_#{feature.to_s.upcase}", nil)
    return ActiveModel::Type::Boolean.new.cast(configured) unless configured.nil?

    Rails.env.test?
  end
end
