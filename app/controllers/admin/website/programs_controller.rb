module Admin
  module Website
    class ProgramsController < Admin::BaseController
      before_action :set_program, only: %i[edit update]

      def index
        @pagy, @programs = pagy(:offset, Program.order(:public_display_order, :display_order, :id), limit: 25)
      end

      def edit; end

      def update
        @program = Admin::Website::UpdateProgramPublicProfile.new(
          actor: current_user, program: @program, attributes: program_params
        ).call
        return render :edit, status: :unprocessable_content if @program.errors.any?

        redirect_to admin_website_programs_path, notice: t("admin.website.programs.messages.updated"),
                                                 status: :see_other
      end

      private

      def set_program = @program = Program.find(params.expect(:id))

      def program_params
        params.expect(program: %i[published slug_ar slug_en public_featured public_display_order])
      end
    end
  end
end
