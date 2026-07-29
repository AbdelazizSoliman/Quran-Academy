class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable,
         :trackable, :timeoutable

  enum :role, { admin: 0, staff: 1, teacher: 2, student: 3 }, validate: true
  enum :status, { pending: 0, active: 1, suspended: 2, disabled: 3 }, validate: true

  before_validation :apply_preference_defaults

  belongs_to :approved_by, class_name: "User", optional: true, inverse_of: :approved_users
  has_many :approved_users, class_name: "User", foreign_key: :approved_by_id,
                            inverse_of: :approved_by, dependent: :nullify
  has_many :account_events, class_name: "UserAccountEvent", foreign_key: :target_user_id,
                            inverse_of: :target_user, dependent: :restrict_with_exception
  has_many :performed_account_events, class_name: "UserAccountEvent", foreign_key: :actor_id,
                                      inverse_of: :actor, dependent: :restrict_with_exception
  has_many :updated_academy_settings, class_name: "AcademySetting", foreign_key: :updated_by_id,
                                      inverse_of: :updated_by, dependent: :nullify
  has_many :academy_setting_events, foreign_key: :actor_id, inverse_of: :actor,
                                    dependent: :restrict_with_exception
  has_one :teacher_profile, inverse_of: :user, dependent: :restrict_with_exception
  has_many :created_teacher_profiles, class_name: "TeacherProfile", foreign_key: :created_by_id,
                                      inverse_of: :created_by, dependent: :nullify
  has_many :updated_teacher_profiles, class_name: "TeacherProfile", foreign_key: :updated_by_id,
                                      inverse_of: :updated_by, dependent: :nullify
  has_many :teacher_profile_events, foreign_key: :actor_id, inverse_of: :actor,
                                    dependent: :restrict_with_exception

  validates :first_name, :last_name, presence: true
  validates :preferred_locale, inclusion: { in: %w[ar en] }
  validates :time_zone, inclusion: { in: ->(_user) { ActiveSupport::TimeZone.all.map(&:name) } }
  validate :teacher_profile_role_integrity, if: :will_save_change_to_role?

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

  def teacher_profile?
    teacher_profile.present?
  end

  private

  def apply_preference_defaults
    self.preferred_locale = student? ? "en" : "ar" if preferred_locale.blank?
    self.time_zone = "Cairo" if time_zone.blank?
  end

  def teacher_profile_role_integrity
    errors.add(:role, :teacher_profile_exists) if persisted? && !teacher? && teacher_profile?
  end
end
