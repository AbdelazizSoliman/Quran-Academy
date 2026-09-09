module Admin
  module WebsiteHelper
    # Publication requires both the operational status and the explicit `published` flag, so the
    # badge distinguishes "published but not operationally eligible" from genuinely public.
    def public_state_badge(published:, operationally_eligible:, scope:)
      state = if published && operationally_eligible
                :public
              elsif published
                :published_not_active
              else
                :hidden
              end
      variants = { public: :success, published_not_active: :warning, hidden: :neutral }
      render "shared/components/badge", label: t("admin.website.#{scope}.states.#{state}"),
                                        variant: variants.fetch(state)
    end

    def public_program_state_badge(program)
      public_state_badge(published: program.published?, operationally_eligible: program.active?, scope: "programs")
    end

    def public_fee_plan_state_badge(fee_plan)
      public_state_badge(published: fee_plan.published?, operationally_eligible: fee_plan.active?, scope: "fee_plans")
    end
  end
end
