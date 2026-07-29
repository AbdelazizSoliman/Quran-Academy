class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable,
         :trackable, :timeoutable

  enum :role, { admin: 0, staff: 1, teacher: 2, student: 3 }, validate: true
  enum :status, { pending: 0, active: 1, suspended: 2, disabled: 3 }, validate: true

  before_validation :apply_preference_defaults

  validates :first_name, :last_name, presence: true
  validates :preferred_locale, inclusion: { in: %w[ar en] }
  validates :time_zone, inclusion: { in: ->(_user) { ActiveSupport::TimeZone.all.map(&:name) } }

  def full_name
    [first_name, last_name].compact_blank.join(" ").presence || email.to_s.split("@").first.presence || "User"
  end

  def active_for_authentication?
    super && active?
  end

  def inactive_message
    return super if active?

    :"#{status}_account"
  end

  private

  def apply_preference_defaults
    self.preferred_locale ||= student? ? "en" : "ar"
    self.time_zone = "Cairo" if time_zone.blank?
  end
end
