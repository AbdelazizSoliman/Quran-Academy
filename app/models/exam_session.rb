class ExamSession < ApplicationRecord
  STATUSES = %w[draft scheduled completed reviewed published archived].freeze

  belongs_to :program
  belongs_to :course_offering
  belongs_to :teacher_profile
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"
  has_many :certificates, dependent: :restrict_with_exception
  has_many :events, class_name: "ExamSessionEvent", dependent: :restrict_with_exception

  attr_readonly :public_id, :program_id, :course_offering_id
  before_validation :generate_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\AEXM-[A-Z0-9]{10}\z/ }
  validates :title, :starts_at, presence: true
  validates :duration_minutes, numericality: { only_integer: true, in: 1..480 }
  validates :status, inclusion: { in: STATUSES }
  validates :notes, length: { maximum: 5_000 }, allow_blank: true
  validate :offering_matches_program

  scope :chronological, -> { order(:starts_at, :id) }
  STATUSES.each { |value| define_method(:"#{value}?") { status == value } }

  private

  def generate_public_id = self.public_id ||= "EXM-#{SecureRandom.alphanumeric(10).upcase}"
  def offering_matches_program
    errors.add(:course_offering, :inconsistent) if course_offering&.program_id != program_id
  end
end
