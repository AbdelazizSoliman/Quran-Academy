module Admin
  module CourseOfferingAssignments
    class Sync
      Result = Data.define(:teachers_count, :enrollments_created, :errors)

      def initialize(actor:, offering:, teacher_ids:, student_ids: nil)
        @actor = actor
        @offering = offering
        @teacher_ids = normalized_ids(teacher_ids)
        @student_ids = student_ids.nil? ? nil : normalized_ids(student_ids)
      end

      def call
        teachers = valid_teachers
        students = valid_students
        errors = selection_errors(teachers, students)
        return Result.new(teachers_count: @offering.teacher_profiles.count, enrollments_created: 0, errors:) if errors.any?

        created_count = 0
        CourseOffering.transaction do
          sync_teachers(teachers)
          created_count = create_enrollments(students, errors)
          raise ActiveRecord::Rollback if errors.any?
        end

        created_count = 0 if errors.any?
        @offering.association(:teacher_profiles).reset
        Result.new(teachers_count: @offering.teacher_profiles.count, enrollments_created: created_count, errors:)
      end

      private

      def normalized_ids(values)
        Array(values).filter_map { |value| Integer(value, exception: false) }.uniq
      end

      def valid_teachers
        TeacherProfile.where(id: @teacher_ids).where.not(profile_status: "archived").to_a
      end

      def valid_students
        return nil if @student_ids.nil?

        StudentProfile.where(id: @student_ids).where.not(profile_status: "archived").to_a
      end

      def selection_errors(teachers, students)
        errors = []
        errors << I18n.t("course_offerings.madarak.invalid_teachers") if teachers.size != @teacher_ids.size
        if !students.nil? && students.size != @student_ids.size
          errors << I18n.t("course_offerings.madarak.invalid_students")
        end
        errors
      end

      def sync_teachers(teachers)
        joins = @offering.course_offering_teachers
        if @teacher_ids.empty?
          joins.delete_all
        else
          joins.where.not(teacher_profile_id: @teacher_ids).delete_all
        end

        existing_ids = joins.where(teacher_profile_id: @teacher_ids).pluck(:teacher_profile_id)
        teachers.reject { |teacher| teacher.id.in?(existing_ids) }.each do |teacher|
          joins.create!(teacher_profile: teacher, created_by: @actor)
        end
      end

      def create_enrollments(students, errors)
        return 0 if students.nil?

        students.count do |student|
          next false if @offering.enrollments.exists?(student_profile: student)

          enrollment = Admin::Enrollments::Create.new(
            actor: @actor, student_profile: student, course_offering: @offering,
            attributes: { application_source: "administrator" }
          ).call
          if enrollment.persisted? && enrollment.errors.empty?
            true
          else
            errors.concat(enrollment.errors.full_messages)
            false
          end
        end
      end
    end
  end
end
