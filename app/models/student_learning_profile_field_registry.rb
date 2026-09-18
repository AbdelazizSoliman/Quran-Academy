class StudentLearningProfileFieldRegistry
  STANDARD = { value_type: "text", sensitivity: "standard", visibility: "internal" }.freeze
  SENSITIVE = STANDARD.merge(sensitivity: "sensitive").freeze
  HIGHLY_SENSITIVE = STANDARD.merge(sensitivity: "highly_sensitive").freeze

  DEFINITIONS = {
    "basic_information" => {
      "instructional_summary" => STANDARD,
      "communication_style" => STANDARD
    },
    "educational_quranic_background" => {
      "previous_learning_experience" => STANDARD,
      "previous_learning_materials" => STANDARD.merge(value_type: "list"),
      "educational_background_notes" => STANDARD,
      "reading_fluency_notes" => STANDARD,
      "pronunciation_challenges" => STANDARD,
      "tajweed_notes" => STANDARD,
      "preferred_explanation_language" => STANDARD,
      "preferred_teaching_materials" => STANDARD.merge(value_type: "list")
    },
    "language_cultural_background" => {
      "spoken_languages" => STANDARD.merge(value_type: "list"),
      "arabic_literacy_context" => STANDARD,
      "cultural_considerations" => SENSITIVE,
      "interaction_language" => STANDARD,
      "pronunciation_accent_notes" => STANDARD,
      "arabic_exposure_outside_lessons" => STANDARD,
      "cultural_context_notes" => SENSITIVE
    },
    "faith_spiritual_context" => {
      "spiritual_learning_goals" => SENSITIVE,
      "encouragement_approach" => SENSITIVE,
      "faith_context_notes" => SENSITIVE
    },
    "cognitive_traits_learning_preferences" => {
      "preferred_activities" => STANDARD.merge(value_type: "list"),
      "preferred_pacing" => STANDARD,
      "helpful_presentation_modes" => STANDARD.merge(value_type: "list"),
      "repetition_preference" => STANDARD,
      "teaching_strategy" => STANDARD,
      "learning_preferences" => STANDARD.merge(sensitivity: "sensitive"),
      "comprehension_pace" => STANDARD,
      "focus_duration_minutes" => STANDARD.merge(value_type: "number"),
      "curiosity_notes" => STANDARD
    },
    "psychological_emotional_state" => {
      "emotional_response" => HIGHLY_SENSITIVE,
      "reassurance_approach" => HIGHLY_SENSITIVE,
      "lesson_readiness_pattern" => HIGHLY_SENSITIVE,
      "general_emotional_observation" => HIGHLY_SENSITIVE,
      "response_to_mistakes" => HIGHLY_SENSITIVE,
      "comfort_on_camera" => HIGHLY_SENSITIVE,
      "response_to_correction" => HIGHLY_SENSITIVE
    },
    "self_regulation_behaviour" => {
      "attention_supports" => SENSITIVE,
      "participation_pattern" => SENSITIVE,
      "break_preference" => STANDARD,
      "behaviour_support_strategy" => SENSITIVE,
      "punctuality_notes" => STANDARD,
      "movement_level" => STANDARD,
      "distraction_pattern" => SENSITIVE,
      "encouragement_response" => STANDARD,
      "activity_engagement_notes" => STANDARD
    },
    "personality_motivation" => {
      "motivation_pattern" => SENSITIVE,
      "feedback_preference" => STANDARD,
      "encouragement_strategy" => STANDARD,
      "persistence_observation" => SENSITIVE,
      "motivation_notes" => SENSITIVE,
      "confidence_notes" => SENSITIVE,
      "competition_preference" => STANDARD,
      "motivators" => STANDARD.merge(value_type: "list"),
      "demotivators" => STANDARD.merge(value_type: "list")
    },
    "interests_personal_culture" => {
      "interests" => STANDARD.merge(value_type: "list"),
      "engaging_topics" => STANDARD.merge(value_type: "list"),
      "preferred_activity_formats" => STANDARD.merge(value_type: "list"),
      "hobbies" => STANDARD.merge(value_type: "list"),
      "preferred_activities" => STANDARD.merge(value_type: "list"),
      "screen_context_notes" => STANDARD
    },
    "family_social_context" => {
      "family_learning_context" => SENSITIVE,
      "home_support_availability" => SENSITIVE,
      "scheduling_context" => SENSITIVE,
      "study_support_context" => SENSITIVE,
      "online_lesson_supervision" => SENSITIVE,
      "social_context_notes" => SENSITIVE
    },
    "achievements_aspirations" => {
      "aspirations" => STANDARD,
      "personal_milestones" => STANDARD.merge(value_type: "list"),
      "recognition_preferences" => STANDARD,
      "achievements_notes" => STANDARD,
      "current_goals" => STANDARD,
      "proud_moments" => STANDARD
    },
    "challenges_support_needs" => {
      "support_context" => SENSITIVE,
      "learning_challenges" => SENSITIVE,
      "support_needs" => SENSITIVE,
      "teaching_adjustments" => SENSITIVE,
      "support_review_date" => STANDARD.merge(value_type: "date"),
      "attention_support_needs" => SENSITIVE,
      "pronunciation_support_needs" => SENSITIVE,
      "break_needs" => SENSITIVE,
      "teaching_support_plan" => SENSITIVE
    }
  }.freeze

  class << self
    def fetch(section_key, field_key) = DEFINITIONS.dig(section_key.to_s, field_key.to_s)
    def keys_for(section_key) = DEFINITIONS.fetch(section_key.to_s, {}).keys.freeze
    def registered?(section_key, field_key) = fetch(section_key, field_key).present?
  end
end
