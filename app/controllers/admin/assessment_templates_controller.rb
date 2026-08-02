module Admin
  class AssessmentTemplatesController < BaseController
    before_action :set_template, except: %i[index new create]

    def index = @templates = AssessmentTemplate.includes(:rubric_items).ordered
    def show; end
    def new = @template = AssessmentTemplate.new(status: "active")
    def edit; end

    def create
      @template = AssessmentTemplate.new(template_params.merge(created_by: current_user, updated_by: current_user))
      save_or_render(:new)
    end

    def update
      @template.assign_attributes(template_params.merge(updated_by: current_user))
      save_or_render(:edit)
    end

    private

    def set_template = @template = AssessmentTemplate.includes(rubric_items: :assessment_category).find(params.expect(:id))
    def template_params
      params.expect(assessment_template: %i[name_ar name_en description status display_order lock_version])
    end

    def save_or_render(view)
      if @template.save
        redirect_to admin_assessment_template_path(@template), notice: t("academic.messages.saved")
      else
        render view, status: :unprocessable_content
      end
    end
  end
end
