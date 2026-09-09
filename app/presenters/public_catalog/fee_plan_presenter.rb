module PublicCatalog
  # Wraps a FeePlan row loaded through PublicCatalog::FeePlansQuery and exposes only the
  # pricing attributes deliberately approved for public display.
  class FeePlanPresenter
    def self.wrap(fee_plans, locale:)
      fee_plans.map { |fee_plan| new(fee_plan, locale:) }
    end

    def initialize(fee_plan, locale:)
      @fee_plan = fee_plan
      @locale = locale.to_s == "ar" ? "ar" : "en"
    end

    attr_reader :locale

    delegate :amount, :currency_symbol, to: :fee_plan

    def name = localized(:name)
    def description = localized(:description)
    def price_note = localized(:price_note)
    def billing_cycle_label = I18n.t("fee_plans.billing_cycles.#{fee_plan.billing_cycle}")
    def features = fee_plan.public_features(locale)

    def cta_label
      localized(:public_cta_label) || I18n.t("public.fees.default_cta")
    end

    private

    attr_reader :fee_plan

    def localized(attribute) = fee_plan.public_send(:"#{attribute}_#{locale}").presence
  end
end
