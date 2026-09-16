class StudentLearningProfile < ApplicationRecord
  belongs_to :student_profile, inverse_of: :student_learning_profile
  belongs_to :created_by, class_name: "User", inverse_of: :created_student_learning_profiles
  belongs_to :updated_by, class_name: "User", inverse_of: :updated_student_learning_profiles

  has_many :sections, class_name: "StudentLearningProfileSection", inverse_of: :student_learning_profile,
                      dependent: :restrict_with_exception
  has_many :items, through: :sections
  has_many :events, class_name: "StudentLearningProfileEvent", inverse_of: :student_learning_profile,
                    dependent: :restrict_with_exception
  has_many :observations, through: :student_profile, source: :student_observations

  attr_readonly :public_id, :student_profile_id
  before_validation :generate_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\ASLP-[A-Z0-9]{10}\z/ }
  validates :student_profile_id, uniqueness: true

  def ordered_sections
    sections.sort_by(&:position)
  end

  private

  def generate_public_id = self.public_id ||= "SLP-#{SecureRandom.alphanumeric(10).upcase}"
end
