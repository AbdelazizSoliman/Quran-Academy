require "rails_helper"

RSpec.describe Admin::TeacherMetrics do
  it "computes weekly utilization from real availability and lessons and counts assigned students" do
    at = Time.zone.local(2026, 8, 11, 12)
    teacher = create(:teacher_profile, :active, :verified)
    create(:teacher_availability, teacher_profile: teacher, weekday: "tuesday",
                                  starts_at_local: "09:00", ends_at_local: "17:00",
                                  effective_from: Date.new(2026, 8, 1))
    create(:scheduled_lesson, :scheduled, teacher_profile: teacher,
                                           starts_at: Time.zone.local(2026, 8, 11, 10),
                                           ends_at: Time.zone.local(2026, 8, 11, 12))
    create_list(:student_profile, 2, assigned_teacher_profile: teacher)
    create(:student_profile, :archived, assigned_teacher_profile: teacher)

    metric = described_class.new(profiles: [teacher], at:).call.fetch(teacher)

    expect(metric).to include(capacity_minutes: 480, scheduled_minutes: 120,
                              utilization_percentage: 25, utilization_bar_percentage: 25,
                              assigned_students_count: 2)
  end

  it "reports unconfigured capacity without inventing a utilization percentage" do
    teacher = create(:teacher_profile, :active)

    metric = described_class.new(profiles: [teacher]).call.fetch(teacher)

    expect(metric).to include(capacity_minutes: 0, utilization_percentage: 0,
                              utilization_bar_percentage: 0)
  end
end
