class PublicAnalyticsEvent < ApplicationRecord
  EVENT_TYPES = %w[
    page_view trial_cta_click contact_click whatsapp_click fee_plan_cta_click
    trial_submitted contact_submitted
  ].freeze
  LOCALES = %w[ar en].freeze
  INQUIRY_TYPES = %w[trial contact].freeze
  MAX_LENGTH = 255

  belongs_to :public_inquiry, optional: true
  belongs_to :fee_plan, optional: true

  validates :event_type, inclusion: { in: EVENT_TYPES }
  validates :locale, inclusion: { in: LOCALES }
  validates :path, :visitor_token, presence: true, length: { maximum: MAX_LENGTH }
  validates :source_path, :referrer, :target, :inquiry_type,
            :utm_source, :utm_medium, :utm_campaign, :utm_term, :utm_content,
            length: { maximum: MAX_LENGTH }, allow_blank: true
  validates :inquiry_type, inclusion: { in: INQUIRY_TYPES }, allow_blank: true
  validates :occurred_at, presence: true

  scope :recent, -> { order(occurred_at: :desc) }
  scope :within, ->(range) { where(occurred_at: range) }
  scope :public_events, -> { where.not(event_type: nil) }

  def self.retention_cutoff(now: Time.current) = now - 90.days
end
