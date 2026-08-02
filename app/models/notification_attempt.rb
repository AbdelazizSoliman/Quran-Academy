class NotificationAttempt < ApplicationRecord
  STATUSES = %w[sending sent delivered failed].freeze

  belongs_to :notification, inverse_of: :attempts
  belongs_to :actor, class_name: "User"

  attr_readonly :notification_id, :actor_id, :attempt_number, :provider, :recipient_address_masked,
                :request_fingerprint, :attempted_at
  validates :attempt_number, numericality: { only_integer: true, greater_than: 0 },
                             uniqueness: { scope: :notification_id }
  validates :provider, :recipient_address_masked, :request_fingerprint, presence: true
  validates :status, inclusion: { in: STATUSES }
  scope :chronological, -> { order(:attempt_number) }
end
