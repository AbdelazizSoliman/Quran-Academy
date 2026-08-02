class StaffProfile < ApplicationRecord
  E164_PATTERN = /\A\+[1-9]\d{7,14}\z/

  belongs_to :user, inverse_of: :staff_profile
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :updated_by, class_name: "User", optional: true

  attr_readonly :public_id, :user_id
  before_validation :apply_defaults, on: :create
  before_validation :generate_public_id, on: :create

  validates :user_id, uniqueness: true
  validates :public_id, presence: true, uniqueness: true, format: { with: /\ASTF-[A-Z0-9]{10}\z/ }
  validates :phone_number, :whatsapp_number, presence: true, format: { with: E164_PATTERN }
  validates :display_name, length: { maximum: 150 }, allow_blank: true
  validate :user_has_administrative_role

  private

  def apply_defaults
    self.display_name ||= user&.full_name
    self.whatsapp_number = phone_number if whatsapp_number.blank?
  end

  def generate_public_id = self.public_id ||= "STF-#{SecureRandom.alphanumeric(10).upcase}"

  def user_has_administrative_role
    errors.add(:user, :invalid_role) unless user&.role.in?(%w[admin staff])
  end
end
