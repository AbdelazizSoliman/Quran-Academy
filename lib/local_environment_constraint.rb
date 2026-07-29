class LocalEnvironmentConstraint
  def matches?(_request)
    Rails.env.local?
  end
end
