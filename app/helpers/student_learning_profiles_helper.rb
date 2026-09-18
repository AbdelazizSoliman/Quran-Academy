module StudentLearningProfilesHelper
  def learning_profile_section_title(key)
    t("learning_profile.sections.#{key}.title", default: key.humanize)
  end

  def learning_profile_field_label(key)
    t("learning_profile.fields.#{key}", default: key.humanize)
  end

  def learning_profile_sensitivity_label(value)
    t("learning_profile.sensitivity.#{value}", default: value.humanize)
  end

  def learning_profile_value(value)
    return if value.nil?
    return value.join(", ") if value.is_a?(Array)

    value.to_s
  end

  def learning_profile_textarea?(field_key)
    compact_fields = %w[preferred_explanation_language interaction_language preferred_pacing comprehension_pace
                        focus_duration_minutes competition_preference movement_level break_preference comfort_on_camera
                        response_to_correction encouragement_response home_support_availability support_review_date]
    compact_fields.exclude?(field_key.to_s)
  end

  def learning_profile_field_id(field_key)
    "learning_profile_item_#{field_key}"
  end
end
