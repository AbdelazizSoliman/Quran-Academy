module Admin
  class AssessmentCategoriesController < BaseController
    before_action :set_category, except: %i[index new create]
    def index = @categories = AssessmentCategory.ordered
    def show; end
    def new = @category = AssessmentCategory.new(active: true)
    def edit; end
    def create = persist(AssessmentCategory.new(category_params.merge(created_by: current_user, updated_by: current_user)), :new)

    def update
      @category.assign_attributes(category_params.merge(updated_by: current_user))
      persist(@category, :edit)
    end

    private

    def set_category = @category = AssessmentCategory.find(params.expect(:id))
    def category_params
      params.expect(assessment_category: %i[code name_ar name_en active display_order lock_version])
    end

    def persist(category, view)
      @category = category
      return redirect_to(admin_assessment_category_path(category), notice: t("academic.messages.saved")) if category.save

      render view, status: :unprocessable_content
    end
  end
end
