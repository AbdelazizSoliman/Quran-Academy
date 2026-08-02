class Certificate < ApplicationRecord
  has_many :notifications, as: :source, dependent: :restrict_with_exception
  TYPES = %w[program_completion exam_completion ijazah].freeze

  belongs_to :student_profile
  belongs_to :enrollment, optional: true
  belongs_to :exam_session, optional: true
  belongs_to :issuer, class_name: "User"
  has_many :events, class_name: "CertificateEvent", dependent: :restrict_with_exception

  attr_readonly :public_id, :student_profile_id, :verification_code
  before_validation :generate_identifiers, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\ACER-[A-Z0-9]{10}\z/ }
  validates :verification_code, presence: true, uniqueness: true,
                                format: { with: /\AVFY-[A-Z0-9]{12}\z/ }
  validates :certificate_type, inclusion: { in: TYPES }
  validates :issued_on, presence: true
  validates :notes, length: { maximum: 3_000 }, allow_blank: true
  validate :source_consistency

  scope :recent_first, -> { order(issued_on: :desc, id: :desc) }

  private

  def generate_identifiers
    self.public_id ||= "CER-#{SecureRandom.alphanumeric(10).upcase}"
    self.verification_code ||= "VFY-#{SecureRandom.alphanumeric(12).upcase}"
    self.qr_placeholder ||= verification_code
  end

  def source_consistency
    errors.add(:enrollment, :inconsistent) if enrollment && enrollment.student_profile_id != student_profile_id
    errors.add(:enrollment, :blank) if certificate_type == "program_completion" && enrollment.nil?
    errors.add(:exam_session, :blank) if certificate_type == "exam_completion" && exam_session.nil?
  end
end
