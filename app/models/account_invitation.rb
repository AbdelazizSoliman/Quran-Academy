class AccountInvitation < ApplicationRecord
  STATUSES = %w[pending sent accepted expired cancelled].freeze

  belongs_to :user
  belongs_to :created_by, class_name: "User"
  has_many :events, class_name: "AccountInvitationEvent", dependent: :restrict_with_exception

  attr_readonly :public_id, :user_id, :created_by_id
  before_validation :generate_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true, format: { with: /\AINV-[A-Z0-9]{10}\z/ }
  validates :token_digest, presence: true, uniqueness: true
  validates :user_id, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :expires_at, presence: true
  validates :resent_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
  STATUSES.each { |value| define_method(:"#{value}?") { status == value } }

  def usable?
    (pending? || sent?) && expires_at.future?
  end

  private

  def generate_public_id = self.public_id ||= "INV-#{SecureRandom.alphanumeric(10).upcase}"
end
