module Admin
  class CertificatesController < SchedulingBaseController
    before_action :require_admin!, except: %i[index show]

    def index
      scope = Certificate.includes(student_profile: :user).recent_first
      @pagy, @certificates = pagy(:offset, scope, limit: 25)
    end

    def show
      @certificate = Certificate.includes(:student_profile, :enrollment, :exam_session, events: :actor)
                                .find(params.expect(:id))
    end

    def new = @certificate = Certificate.new(issued_on: Date.current)

    def create
      @certificate = Certificates::Issue.new(actor: current_user, attributes: certificate_params).call
      if @certificate.errors.empty?
        redirect_to admin_certificate_path(@certificate), notice: t("academic.messages.saved")
      else
        render :new, status: :unprocessable_content
      end
    end

    private

    def certificate_params
      params.expect(certificate: %i[student_profile_id enrollment_id exam_session_id certificate_type issued_on notes])
    end
  end
end
