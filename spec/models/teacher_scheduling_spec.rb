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

    it "repairs a concatenated meeting URL and accepts a complete Teams URL" do
      lesson = build(:scheduled_lesson,
                     online_meeting_url: "https://www.jiroxy.tvhttps//teams.live.com/meet/9315722123436")
      expect(lesson).to be_valid
      expect(lesson.online_meeting_url).to eq("https://teams.live.com/meet/9315722123436")

      lesson.online_meeting_url = "https://teams.live.com/meet/9315722123436?p=rm3pIwI0sfIRBAU9pC"
      expect(lesson).to be_valid
    end

    it "rejects a meeting URL without an HTTP or HTTPS scheme" do
      lesson = build(:scheduled_lesson, online_meeting_url: "teams.live.com/meet/9315722123436")
      expect(lesson).not_to be_valid
    end

    it "resolves a lesson override before the teacher default" do
      teacher = build(:teacher_profile, online_meeting_url: "https://meet.example.test/teacher")
      lesson = build(:scheduled_lesson, teacher_profile: teacher,
                                        online_meeting_url: "https://meet.example.test/lesson")

      expect(lesson.effective_online_meeting_url).to eq("https://meet.example.test/lesson")
    end

    it "falls back to the teacher default and returns nil when both URLs are blank" do
      teacher = build(:teacher_profile, online_meeting_url: "https://meet.example.test/teacher")
      lesson = build(:scheduled_lesson, teacher_profile: teacher, online_meeting_url: nil)
      expect(lesson.effective_online_meeting_url).to eq("https://meet.example.test/teacher")

      teacher.online_meeting_url = nil
      expect(lesson.effective_online_meeting_url).to be_nil
    end

    it "allows an online lesson with a teacher default but rejects one with no usable URL" do
      teacher = build(:teacher_profile, online_meeting_url: "https://meet.example.test/teacher")
      expect(build(:scheduled_lesson, :scheduled, teacher_profile: teacher, online_meeting_url: nil)).to be_valid

      teacher.online_meeting_url = nil
      expect(build(:scheduled_lesson, :scheduled, teacher_profile: teacher, online_meeting_url: nil)).not_to be_valid
    end

    it "leaves onsite lesson URL validation requirements unchanged" do
      lesson = build(:scheduled_lesson, :scheduled, delivery_mode: "onsite", location_name: "Room 1",
                                                online_meeting_url: nil)
      expect(lesson).to be_valid
    end

    it "dynamically follows teacher changes only when there is no lesson override" do
      teacher = create(:teacher_profile, online_meeting_url: "https://meet.example.test/original")
      inherited = create(:scheduled_lesson, teacher_profile: teacher, online_meeting_url: nil)
      overridden = create(:scheduled_lesson, teacher_profile: teacher,
                                             online_meeting_url: "https://meet.example.test/lesson")

      teacher.update!(online_meeting_url: "https://meet.example.test/replacement")

      expect(inherited.reload.effective_online_meeting_url).to eq("https://meet.example.test/replacement")
      expect(overridden.reload.effective_online_meeting_url).to eq("https://meet.example.test/lesson")
    end

    it "requires participants to belong to the same offering" do
      lesson = create(:scheduled_lesson)
      participant = build(:scheduled_lesson_enrollment, scheduled_lesson: lesson)
      participant.enrollment.course_offering = create(:course_offering, :open)
      expect(participant).not_to be_valid
    end
  end
end
