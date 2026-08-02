module Admin
  class AssessmentRubricItemsController < BaseController
    before_action :set_template

    def create
      @item = @template.rubric_items.new(item_params)
      respond
    end

    def update
      @item = @template.rubric_items.find(params.expect(:id))
      @item.assign_attributes(item_params)
      respond
    end

    private

    def set_template = @template = AssessmentTemplate.find(params.expect(:assessment_template_id))
    def item_params
      params.expect(assessment_rubric_item: %i[assessment_category_id name_ar name_en scoring_type maximum_score
                                                weight display_order required lock_version])
    end

    def respond
      if @item.save
        redirect_to admin_assessment_template_path(@template), notice: t("academic.messages.saved")
      else
        redirect_to admin_assessment_template_path(@template), alert: @item.errors.full_messages.to_sentence
      end
    end
  end
end
