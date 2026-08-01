require "rails_helper"

RSpec.describe TeacherScheduling do
  describe TeacherAvailability do
    it "validates recurring windows and immutable identifiers" do
      availability = create(:teacher_availability)
      expect(availability.public_id).to match(/\ATAV-/)
      expect { availability.update!(public_id: "TAV-AAAAAAAAAA") }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    end

    it "rejects overlapping active recurring windows" do
      availability = create(:teacher_availability)
      duplicate = build(:teacher_availability, teacher_profile: availability.teacher_profile, weekday: "monday",
                                               starts_at_local: "11:00", ends_at_local: "13:00")
      expect(duplicate).not_to be_valid
    end
  end

  describe TeacherAvailabilityException do
    it "supports full-day exceptions and rejects unpaired times" do
      exception = build(:teacher_availability_exception, starts_at_local: nil, ends_at_local: nil)
      expect(exception).to be_valid
      exception.starts_at_local = "09:00"
      expect(exception).not_to be_valid
    end
  end

  describe ScheduledLesson do
    it "requires delivery details before scheduling" do
      lesson = build(:scheduled_lesson, delivery_mode: "onsite", location_name: nil, status: "scheduled")
      expect(lesson).not_to be_valid
    end

    it "requires participants to belong to the same offering" do
      lesson = create(:scheduled_lesson)
      participant = build(:scheduled_lesson_enrollment, scheduled_lesson: lesson)
      participant.enrollment.course_offering = create(:course_offering, :open)
      expect(participant).not_to be_valid
    end
  end
end
