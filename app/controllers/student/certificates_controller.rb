module Student
  class CertificatesController < BaseController
    def index = @certificates = query.certificates
    def show = @certificate = query.certificates.find(params.expect(:id))

    private

    def query = AcademicRecordsQuery.new(student_profile: current_user.student_profile)
  end
end
