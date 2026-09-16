class StudentLearningProfileSectionRegistry
  DEFINITIONS = {
    "basic_information" => { position: 1, importance: "must" },
    "educational_quranic_background" => { position: 2, importance: "must" },
    "language_cultural_background" => { position: 3, importance: "should" },
    "faith_spiritual_context" => { position: 4, importance: "should" },
    "cognitive_traits_learning_preferences" => { position: 5, importance: "must" },
    "psychological_emotional_state" => { position: 6, importance: "must" },
    "self_regulation_behaviour" => { position: 7, importance: "must" },
    "personality_motivation" => { position: 8, importance: "must" },
    "interests_personal_culture" => { position: 9, importance: "could" },
    "family_social_context" => { position: 10, importance: "should" },
    "achievements_aspirations" => { position: 11, importance: "could" },
    "challenges_support_needs" => { position: 12, importance: "must" }
  }.freeze

  class << self
    def keys = DEFINITIONS.keys.freeze
    def fetch(key) = DEFINITIONS[key.to_s]
    def each(&) = DEFINITIONS.each(&)
  end
end
